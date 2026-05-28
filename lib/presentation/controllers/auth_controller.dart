import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  String? _errorCode;
  String? _errorStage;
  String? _errorRawDetail;
  Map<String, dynamic>? _userData;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  String? get errorCode => _errorCode;
  String? get errorStage => _errorStage;
  String? get errorRawDetail => _errorRawDetail;
  Map<String, dynamic>? get userData => _userData;

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
      _status = AuthStatus.error;
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
    notifyListeners();
  }
}
