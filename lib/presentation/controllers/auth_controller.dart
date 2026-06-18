import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

/// Tipe flow OTP — menentukan aksi yang dilakukan setelah OTP diverifikasi.
enum AuthFlowType { register, login }

class AuthController extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  String? _errorCode;
  String? _errorStage;
  String? _errorRawDetail;
  Map<String, dynamic>? _userData;

  // State OTP flow
  String? _verificationId;
  int? _resendToken;
  bool _isOtpLoading = false;
  bool _isOtpSent = false;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  String? get errorStage => _errorStage;
  String? get errorRawDetail => _errorRawDetail;
  Map<String, dynamic>? get userData => _userData;

  String? get verificationId => _verificationId;
  int? get resendToken => _resendToken;
  bool get isOtpLoading => _isOtpLoading;
  bool get isOtpSent => _isOtpSent;

  // =========================================================================
  // OTP METHODS
  // =========================================================================

  /// Kirim OTP ke nomor HP.
  /// Mengembalikan true jika berhasil, false jika gagal.
  Future<bool> sendOtp({
    required String phoneNumber,
    Function(PhoneAuthCredential credential)? onAutoVerified,
  }) async {
    _isOtpLoading = true;
    _isOtpSent = false;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    final completer = Completer<bool>();

    await _repo.sendOtp(
      phoneNumber: phoneNumber,
      resendToken: _resendToken,
      onCodeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        _isOtpSent = true;
        _isOtpLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(true);
      },
      onFailed: (FirebaseAuthException e) {
        _errorMessage = e.message ?? 'Gagal mengirim OTP.';
        _errorCode = 'OTP_SEND_FAILED';
        _isOtpLoading = false;
        notifyListeners();
        if (!completer.isCompleted) completer.complete(false);
      },
      onAutoVerified: (PhoneAuthCredential credential) {
        if (onAutoVerified != null) {
          onAutoVerified(credential);
        }
        // In some cases with test numbers, Firebase triggers onAutoVerified instantly.
        // We must complete the completer so the UI doesn't hang.
        if (!completer.isCompleted) completer.complete(true);
      },
    );

    return completer.future;
  }

  /// Verifikasi OTP untuk alur REGISTRASI.
  /// Setelah sukses: akun Firebase terbuat + HP ter-link.
  Future<UserCredential?> verifyOtpAndSignUp({
    required String otpCode,
    required String email,
    required String password,
  }) async {
    if (_verificationId == null) {
      _errorMessage = 'Sesi OTP tidak ditemukan. Kirim ulang OTP.';
      _errorCode = 'NO_VERIFICATION_ID';
      notifyListeners();
      return null;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final credential = await _repo.verifyOtpAndSignUp(
        verificationId: _verificationId!,
        otpCode: otpCode,
        email: email,
        password: password,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return credential;
    } on OtpException catch (e) {
      _errorMessage = e.userMessage;
      _errorCode = e.debugCode;
      _errorRawDetail = e.rawMessage;
      _status = AuthStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Verifikasi OTP untuk alur LOGIN.
  Future<UserCredential?> verifyOtpAndLogin({
    required String otpCode,
  }) async {
    if (_verificationId == null) {
      _errorMessage = 'Sesi OTP tidak ditemukan. Kirim ulang OTP.';
      _errorCode = 'NO_VERIFICATION_ID';
      notifyListeners();
      return null;
    }

    _status = AuthStatus.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      final credential = await _repo.verifyOtpAndLogin(
        verificationId: _verificationId!,
        otpCode: otpCode,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return credential;
    } on OtpException catch (e) {
      _errorMessage = e.userMessage;
      _errorCode = e.debugCode;
      _errorRawDetail = e.rawMessage;
      _status = AuthStatus.error;
      notifyListeners();
      return null;
    }
  }

  /// Selesaikan registrasi: buat dokumen Firestore via backend.
  Future<bool> completeRegistration({
    required String uid,
    required String name,
    required String email,
    required String phone,
  }) async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _repo.completeRegistration(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on OtpException catch (e) {
      _errorMessage = e.userMessage;
      _errorCode = e.debugCode;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Validasi data registrasi ke backend sebelum kirim OTP.
  Future<bool> validateRegistration({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _errorCode = null;
    notifyListeners();

    try {
      await _repo.validateRegistration(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      _status = AuthStatus.idle;
      notifyListeners();
      return true;
    } on OtpException catch (e) {
      _errorMessage = e.userMessage;
      _errorCode = e.debugCode;
      _errorRawDetail = e.rawMessage;
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
      _errorCode = 'NETWORK_ERROR';
      _status = AuthStatus.error;
      notifyListeners();
      return false;
    }
  }

  /// Reset OTP state — dipanggil saat user kembali dari OtpPage.
  void resetOtpState() {
    _verificationId = null;
    _resendToken = null;
    _isOtpSent = false;
    _isOtpLoading = false;
    notifyListeners();
  }

  // =========================================================================
  // GOOGLE SIGN IN (EXISTING)
  // =========================================================================

  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _errorCode = null;
    _errorStage = null;
    _errorRawDetail = null;
    notifyListeners();

    try {
      final result = await _repo.signInWithGoogle();
      _userData = result['data'] as Map<String, dynamic>?;
      _status = AuthStatus.authenticated;
    } on GoogleLoginException catch (e) {
      _errorMessage = e.userMessage;
      _errorCode = e.debugCode;
      _errorStage = e.stage;
      _errorRawDetail = e.rawMessage;
      if (e.debugCode == 'GOOGLE_CANCELLED') {
        _status = AuthStatus.idle;
      } else {
        _status = AuthStatus.error;
      }
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _errorCode = 'GOOGLE_LOGIN_EXCEPTION';
      _errorStage = 'unknown';
      _errorRawDetail = e.toString();
      _status = AuthStatus.error;
    }

    notifyListeners();
  }

  Future<void> signOut() async {
    await _repo.signOut();
    _userData = null;
    _status = AuthStatus.unauthenticated;
    resetOtpState();
    notifyListeners();
  }
}
