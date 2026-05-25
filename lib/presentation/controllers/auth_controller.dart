import 'package:flutter/material.dart';
import '../../data/repositories/auth_repository.dart';

enum AuthStatus { idle, loading, authenticated, unauthenticated, error }

class AuthController extends ChangeNotifier {
  final AuthRepository _repo = AuthRepository();

  AuthStatus _status = AuthStatus.idle;
  String? _errorMessage;
  Map<String, dynamic>? _userData;

  AuthStatus get status => _status;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get userData => _userData;

  Future<void> signInWithGoogle() async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repo.signInWithGoogle();
      _userData = result['data'] as Map<String, dynamic>?;
      _status = AuthStatus.authenticated;
    } on Exception catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
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
