import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionService {
  const AuthSessionService();

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      // Normalize base64Url string
      String normalizedPayload = parts[1];
      switch (normalizedPayload.length % 4) {
        case 2:
          normalizedPayload += '==';
          break;
        case 3:
          normalizedPayload += '=';
          break;
      }

      final payload = utf8.decode(base64Url.decode(normalizedPayload));
      final Map<String, dynamic> json = jsonDecode(payload);
      final exp = json['exp'] as int?;
      if (exp == null) return true;

      final expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      // Check if it expires in less than 5 minutes
      return expiryTime.isBefore(DateTime.now().add(const Duration(minutes: 5)));
    } catch (_) {
      return true;
    }
  }

  Future<String?> getValidIdToken({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      try {
        final freshToken = await currentUser.getIdToken(forceRefresh);
        if (freshToken != null && freshToken.isNotEmpty) {
          await prefs.setString('token', freshToken);
          await prefs.setString('user_id', currentUser.uid);
          return freshToken;
        }
      } catch (_) {
        // Fall back to stored token only if it's not expired
      }
    }

    final savedToken = prefs.getString('token')?.trim() ?? '';
    if (savedToken.isEmpty || _isTokenExpired(savedToken)) {
      return null;
    }
    return savedToken;
  }

  Future<bool> hasValidSessionHint() async {
    final token = await getValidIdToken();
    return token != null && token.isNotEmpty;
  }
}
