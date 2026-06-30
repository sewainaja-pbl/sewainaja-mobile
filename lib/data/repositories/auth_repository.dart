import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

/// Exception untuk OTP flow.
class OtpException implements Exception {
  final String userMessage;
  final String debugCode;
  final String? rawMessage;

  const OtpException({
    required this.userMessage,
    required this.debugCode,
    this.rawMessage,
  });

  @override
  String toString() => '$debugCode | $userMessage | ${rawMessage ?? ''}';
}

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb
        ? '1073702990942-l3rf6d0h9fg0ds386f06cj32avn4dnhg.apps.googleusercontent.com'
        : null,
  );

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

  // =========================================================================
  // OTP PHONE AUTH METHODS
  // =========================================================================

  Future<void> sendOtp({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(FirebaseAuthException e) onFailed,
    required void Function(PhoneAuthCredential credential) onAutoVerified,
    int? resendToken,
  }) async {
    try {
      debugPrint('==== STARTING FIREBASE verifyPhoneNumber for $phoneNumber ====');
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        forceResendingToken: resendToken,
        verificationCompleted: (credential) {
          debugPrint('==== verifyPhoneNumber: verificationCompleted ====');
          onAutoVerified(credential);
        },
        verificationFailed: (e) {
          debugPrint('==== verifyPhoneNumber: verificationFailed ====');
          debugPrint('Error Code: ${e.code}');
          debugPrint('Error Message: ${e.message}');
          onFailed(e);
        },
        codeSent: (verificationId, resendToken) {
          debugPrint('==== verifyPhoneNumber: codeSent ====');
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('==== verifyPhoneNumber: timeout ====');
        },
      );
    } catch (e) {
      debugPrint('==== verifyPhoneNumber: SYNCHRONOUS EXCEPTION ====');
      debugPrint(e.toString());
      onFailed(FirebaseAuthException(code: 'UNKNOWN', message: e.toString()));
    }
  }

  /// Verifikasi OTP untuk alur REGISTRASI:
  /// 1. Buat akun email/password di Firebase Auth
  /// 2. Link nomor HP ke akun tersebut via PhoneAuthCredential
  /// 3. Kembalikan UserCredential yang sudah ter-link
  Future<UserCredential> verifyOtpAndSignUp({
    required String verificationId,
    required String otpCode,
    required String email,
    required String password,
  }) async {
    try {
      // Bangun credential dari verificationId + kode OTP
      final PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      UserCredential emailCredential;
      try {
        // Buat akun email/password terlebih dahulu
        emailCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Jika email sudah ada, mungkin ini adalah akun orphaned dari percobaan sebelumnya yang gagal di tengah jalan.
          // Coba login untuk melanjutkan proses linking.
          emailCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      // Link nomor HP ke akun
      try {
        await emailCredential.user!.linkWithCredential(phoneCredential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'provider-already-linked' || e.code == 'credential-already-in-use') {
          // Jika sudah ter-link, abaikan error ini
        } else {
          rethrow; // Error lain seperti kode OTP salah (invalid-verification-code)
        }
      }

      return emailCredential;
    } on FirebaseAuthException catch (e) {
      throw _mapOtpFirebaseError(e);
    } catch (e) {
      throw OtpException(
        userMessage: 'Terjadi kesalahan saat membuat akun. Coba lagi.',
        debugCode: 'OTP_SIGNUP_UNKNOWN',
        rawMessage: e.toString(),
      );
    }
  }

  /// Verifikasi OTP untuk alur LOGIN:
  /// Verifikasi kode OTP menggunakan credential yang ada.
  /// Tidak membuat akun baru — hanya konfirmasi kepemilikan nomor HP.
  Future<UserCredential> verifyOtpAndLogin({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      final PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );

      // Re-authenticate user yang sudah login dengan credential telepon
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw const OtpException(
          userMessage: 'Sesi tidak ditemukan. Silakan login ulang.',
          debugCode: 'OTP_LOGIN_NO_USER',
        );
      }

      return await user.reauthenticateWithCredential(phoneCredential);
    } on FirebaseAuthException catch (e) {
      throw _mapOtpFirebaseError(e);
    } on OtpException {
      rethrow;
    } catch (e) {
      throw OtpException(
        userMessage: 'Terjadi kesalahan saat verifikasi OTP. Coba lagi.',
        debugCode: 'OTP_LOGIN_UNKNOWN',
        rawMessage: e.toString(),
      );
    }
  }

  /// Selesaikan registrasi: panggil backend untuk buat dokumen Firestore
  /// dan set custom claims. Dipanggil setelah OTP berhasil diverifikasi.
  Future<void> completeRegistration({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    final idToken = await _firebaseAuth.currentUser?.getIdToken();
    if (idToken == null) {
      throw const OtpException(
        userMessage: 'Token tidak ditemukan. Silakan ulangi proses registrasi.',
        debugCode: 'COMPLETE_REGISTER_NO_TOKEN',
      );
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/complete-register'),
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email, 'phone': phone}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final message = data['error']?['message']?.toString();
      throw OtpException(
        userMessage: message ?? 'Gagal menyelesaikan registrasi.',
        debugCode: data['error']?['code']?.toString() ?? 'COMPLETE_REGISTER_FAILED',
        rawMessage: 'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Validasi input registrasi ke backend sebelum trigger OTP.
  /// Backend hanya cek duplikasi email & phone — belum buat akun Firebase.
  Future<void> validateRegistration({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final message = data['error']?['message']?.toString();
      final code = data['error']?['code']?.toString() ?? 'VALIDATION_FAILED';
      throw OtpException(
        userMessage: message ?? 'Validasi gagal.',
        debugCode: code,
        rawMessage: 'HTTP ${response.statusCode}: ${response.body}',
      );
    }
  }

  /// Map FirebaseAuthException dari OTP flow ke OtpException yang user-friendly.
  OtpException _mapOtpFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return OtpException(
          userMessage: 'Kode OTP tidak valid. Periksa kembali kode yang Anda masukkan.',
          debugCode: 'OTP_INVALID_CODE',
          rawMessage: e.message,
        );
      case 'invalid-verification-id':
        return OtpException(
          userMessage: 'Sesi OTP tidak valid atau sudah kedaluwarsa. Kirim ulang OTP.',
          debugCode: 'OTP_INVALID_VERIFICATION_ID',
          rawMessage: e.message,
        );
      case 'session-expired':
        return OtpException(
          userMessage: 'Sesi OTP sudah berakhir. Silakan kirim ulang OTP.',
          debugCode: 'OTP_SESSION_EXPIRED',
          rawMessage: e.message,
        );
      case 'too-many-requests':
        return OtpException(
          userMessage: 'Terlalu banyak percobaan. Tunggu beberapa menit sebelum mencoba lagi.',
          debugCode: 'OTP_TOO_MANY_REQUESTS',
          rawMessage: e.message,
        );
      case 'email-already-in-use':
        return OtpException(
          userMessage: 'Email ini sudah digunakan oleh akun lain.',
          debugCode: 'EMAIL_TAKEN',
          rawMessage: e.message,
        );
      case 'phone-number-already-exists':
        return OtpException(
          userMessage: 'Nomor HP ini sudah terdaftar.',
          debugCode: 'PHONE_TAKEN',
          rawMessage: e.message,
        );
      case 'provider-already-linked':
        return OtpException(
          userMessage: 'Akun ini sudah terhubung ke nomor HP yang berbeda.',
          debugCode: 'PHONE_ALREADY_LINKED',
          rawMessage: e.message,
        );
      case 'network-request-failed':
        return OtpException(
          userMessage: 'Koneksi internet bermasalah. Coba lagi setelah koneksi stabil.',
          debugCode: 'OTP_NETWORK_ERROR',
          rawMessage: e.message,
        );
      default:
        return OtpException(
          userMessage: e.message ?? 'Verifikasi OTP gagal. Coba lagi.',
          debugCode: 'OTP_FIREBASE_${e.code.toUpperCase().replaceAll('-', '_')}',
          rawMessage: e.message,
        );
    }
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
