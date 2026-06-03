import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_config.dart';

class GoogleLoginException implements Exception {
  final String userMessage;
  final String debugCode;
  final String stage;
  final String? rawMessage;

  const GoogleLoginException({
    required this.userMessage,
    required this.debugCode,
    required this.stage,
    this.rawMessage,
  });

  @override
  String toString() => '$debugCode|$stage|$userMessage|${rawMessage ?? ''}';
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const GoogleLoginException(
          userMessage: 'Login Google dibatalkan.',
          debugCode: 'GOOGLE_CANCELLED',
          stage: 'google_sign_in',
          rawMessage: 'User closed Google account picker before completing sign in.',
        );
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final String? idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw const GoogleLoginException(
          userMessage: 'Token Google tidak berhasil diambil. Silakan coba lagi.',
          debugCode: 'GOOGLE_ID_TOKEN_EMPTY',
          stage: 'firebase_token',
          rawMessage: 'Firebase user returned null ID token after Google credential sign in.',
        );
      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login-google'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return body;
      }

      final apiMessage = body['error']?['message']?.toString().trim();
      final apiCode =
          body['error']?['code']?.toString().trim().replaceAll(' ', '_') ??
          'BACKEND_LOGIN_GOOGLE_FAILED';
      throw GoogleLoginException(
        userMessage: (apiMessage != null && apiMessage.isNotEmpty)
            ? apiMessage
            : 'Gagal login dengan Google.',
        debugCode: apiCode.isEmpty ? 'BACKEND_LOGIN_GOOGLE_FAILED' : apiCode,
        stage: 'backend_login_google',
        rawMessage: 'HTTP ${response.statusCode}: ${response.body}',
      );
    } on PlatformException catch (e) {
      throw _mapGooglePlatformError(e);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthError(e);
    } on GoogleLoginException {
      rethrow;
    } catch (e) {
      throw GoogleLoginException(
        userMessage: 'Gagal login dengan Google. Coba lagi sebentar lagi.',
        debugCode: 'GOOGLE_LOGIN_UNKNOWN',
        stage: 'unknown',
        rawMessage: e.toString(),
      );
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  User? get currentUser => _firebaseAuth.currentUser;

  GoogleLoginException _mapGooglePlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();
    final rawMessage = 'PlatformException(code: ${error.code}, message: ${error.message ?? '-'}, details: ${error.details ?? '-'})';

    if (code == 'sign_in_failed' &&
        (message.contains('10') ||
            message.contains('api10') ||
            message.contains('api 10') ||
            message.contains('developer_error'))) {
      return GoogleLoginException(
        userMessage:
            'Google Sign-In Android belum terkonfigurasi dengan benar. Cek SHA-1/SHA-256 dan OAuth client di Firebase.',
        debugCode: 'GOOGLE_DEVELOPER_ERROR',
        stage: 'google_sign_in',
        rawMessage: rawMessage,
      );
    }
    if (code == 'network_error') {
      return GoogleLoginException(
        userMessage: 'Jaringan bermasalah. Coba lagi setelah koneksi stabil.',
        debugCode: 'GOOGLE_NETWORK_ERROR',
        stage: 'google_sign_in',
        rawMessage: rawMessage,
      );
    }
    if (code == 'sign_in_canceled' || code == 'canceled') {
      return GoogleLoginException(
        userMessage: 'Login Google dibatalkan.',
        debugCode: 'GOOGLE_CANCELLED',
        stage: 'google_sign_in',
        rawMessage: rawMessage,
      );
    }

    return GoogleLoginException(
      userMessage: 'Gagal login dengan Google. Coba lagi sebentar lagi.',
      debugCode: 'GOOGLE_PLATFORM_ERROR',
      stage: 'google_sign_in',
      rawMessage: rawMessage,
    );
  }

  GoogleLoginException _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return GoogleLoginException(
          userMessage: 'Email ini sudah terhubung ke metode login lain.',
          debugCode: 'FIREBASE_ACCOUNT_EXISTS_DIFFERENT_CREDENTIAL',
          stage: 'firebase_auth',
          rawMessage: error.message,
        );
      case 'invalid-credential':
        return GoogleLoginException(
          userMessage: 'Kredensial Google tidak valid. Silakan coba lagi.',
          debugCode: 'FIREBASE_INVALID_CREDENTIAL',
          stage: 'firebase_auth',
          rawMessage: error.message,
        );
      case 'user-disabled':
        return GoogleLoginException(
          userMessage: 'Akun ini sedang dinonaktifkan.',
          debugCode: 'FIREBASE_USER_DISABLED',
          stage: 'firebase_auth',
          rawMessage: error.message,
        );
      case 'network-request-failed':
        return GoogleLoginException(
          userMessage: 'Jaringan bermasalah. Coba lagi setelah koneksi stabil.',
          debugCode: 'FIREBASE_NETWORK_REQUEST_FAILED',
          stage: 'firebase_auth',
          rawMessage: error.message,
        );
      default:
        return GoogleLoginException(
          userMessage: error.message ?? 'Gagal login dengan Google.',
          debugCode: 'FIREBASE_${error.code.toUpperCase().replaceAll('-', '_')}',
          stage: 'firebase_auth',
          rawMessage: error.message,
        );
    }
  }
}
