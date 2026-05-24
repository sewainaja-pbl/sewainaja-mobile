import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthSessionService {
  const AuthSessionService();

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
        // Fall back to the last stored token below.
      }
    }

    final savedToken = prefs.getString('token')?.trim() ?? '';
    if (savedToken.isEmpty) {
      return null;
    }
    return savedToken;
  }

  Future<bool> hasValidSessionHint() async {
    final token = await getValidIdToken();
    return token != null && token.isNotEmpty;
  }
}
