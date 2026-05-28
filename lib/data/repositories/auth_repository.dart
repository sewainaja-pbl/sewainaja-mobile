import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_config.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) throw Exception('LOGIN_CANCELLED');

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final String? idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('FAILED_GET_TOKEN');

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

      final apiMessage =
          body['error']?['message']?.toString() ??
          body['error']?['code']?.toString() ??
          'Gagal login dengan Google.';
      throw Exception(apiMessage);
    } on PlatformException catch (e) {
      throw Exception(_mapGooglePlatformError(e));
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapFirebaseAuthError(e));
    } on Exception catch (e) {
      throw Exception(_mapGenericGoogleError(e.toString()));
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

  String _mapGooglePlatformError(PlatformException error) {
    final code = error.code.toLowerCase();
    final message = (error.message ?? '').toLowerCase();

    if (code == 'sign_in_failed' &&
        (message.contains('api10') ||
            message.contains('api 10') ||
            message.contains('developer_error'))) {
      return 'Google Sign-In Android belum terkonfigurasi dengan benar. Cek SHA-1/SHA-256 dan OAuth client di Firebase.';
    }
    if (code == 'network_error') {
      return 'Jaringan bermasalah. Coba lagi setelah koneksi stabil.';
    }
    if (code == 'sign_in_canceled' || code == 'canceled') {
      return 'Login Google dibatalkan.';
    }

    return 'Gagal login dengan Google. Coba lagi sebentar lagi.';
  }

  String _mapFirebaseAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'Email ini sudah terhubung ke metode login lain.';
      case 'invalid-credential':
        return 'Kredensial Google tidak valid. Silakan coba lagi.';
      case 'user-disabled':
        return 'Akun ini sedang dinonaktifkan.';
      case 'network-request-failed':
        return 'Jaringan bermasalah. Coba lagi setelah koneksi stabil.';
      default:
        return error.message ?? 'Gagal login dengan Google.';
    }
  }

  String _mapGenericGoogleError(String raw) {
    final normalized = raw.replaceFirst('Exception: ', '');
    if (normalized == 'LOGIN_CANCELLED') {
      return 'Login Google dibatalkan.';
    }
    if (normalized == 'FAILED_GET_TOKEN') {
      return 'Token Google tidak berhasil diambil. Silakan coba lagi.';
    }
    if (normalized == 'UNAUTHORIZED') {
      return 'Sesi Google tidak valid. Silakan coba login ulang.';
    }
    if (normalized == 'UNKNOWN_ERROR') {
      return 'Gagal login dengan Google.';
    }
    return normalized;
  }
}
