import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../api_config.dart';

class AuthRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Login via Google.
  /// Jika user belum terdaftar, backend akan auto-register (status: pending).
  Future<Map<String, dynamic>> signInWithGoogle() async {
    // 1. Trigger Google Sign-In
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('LOGIN_CANCELLED');

    // 2. Ambil credentials
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 3. Sign in ke Firebase Auth
    final UserCredential userCredential =
        await _firebaseAuth.signInWithCredential(credential);

    // 4. Ambil Firebase ID Token untuk dikirim ke backend
    final String? idToken = await userCredential.user?.getIdToken();
    if (idToken == null) throw Exception('FAILED_GET_TOKEN');

    // 5. Kirim ke backend — satu endpoint yang handle login & auto-register
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

    // Tangani error dari backend
    final code = body['error']?['code'] ?? 'UNKNOWN_ERROR';
    throw Exception(code);
  }

  /// Sign out dari Google dan Firebase
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  /// Ambil ID token terbaru (untuk request API lain setelah login)
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _firebaseAuth.currentUser?.getIdToken(forceRefresh);
  }

  User? get currentUser => _firebaseAuth.currentUser;
}
