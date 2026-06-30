import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../../app_feedback.dart';
import '../../../api_config.dart';
import '../../../notification_service.dart';
import '../../../main_navigation_screen.dart';
import '../../../core/utils/phone_formatter.dart';
import 'otp_page.dart';

/// Halaman login dengan email & password, diikuti verifikasi OTP nomor HP.
///
/// Alur:
/// 1. User isi email + password
/// 2. Firebase signInWithEmailAndPassword
/// 3. Ambil nomor HP dari profil user (via backend GET /auth/profile)
/// 4. Firebase kirim OTP ke nomor HP user
/// 5. Navigasi ke OtpPage dengan flowType = login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showAppErrorSnack(context, 'Harap isi email dan password.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Langkah 1: Login dengan email & password di Firebase
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      final user = userCredential.user;
      if (user == null) {
        showAppErrorSnack(context, 'Login gagal. Silakan coba lagi.');
        return;
      }

      // Langkah 2: Ambil nomor HP dari profil user via backend
      final idToken = await user.getIdToken();
      final profileResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
      );

      if (!mounted) return;

      String? phoneNumber;

      if (profileResponse.statusCode == 200) {
        final profileData =
            jsonDecode(profileResponse.body) as Map<String, dynamic>;
        phoneNumber =
            profileData['data']?['phone']?.toString().trim();
      }

      // Jika user belum punya nomor HP, langsung masuk ke home
      // (Admin atau user yang register via Google mungkin belum punya HP)
      if (phoneNumber == null || phoneNumber.isEmpty) {
        await _finalizeLogin(user, idToken!);
        return;
      }

      // Langkah 3: Kirim OTP ke nomor HP user
      final authController = context.read<AuthController>();
      showAppSuccessSnack(
        context,
        'Mengirim OTP ke ${PhoneFormatter.maskPhone(phoneNumber)}...',
      );

      final otpSent = await authController.sendOtp(phoneNumber: phoneNumber);

      if (!mounted) return;

      if (!otpSent) {
        showAppErrorSnack(
          context,
          authController.errorMessage ?? 'Gagal mengirim OTP. Coba lagi.',
        );
        return;
      }

      showAppSuccessSnack(context, 'Kode OTP berhasil dikirim!');

      // Langkah 4: Navigasi ke OtpPage
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpPage(
            phoneNumber: phoneNumber!,
            flowType: AuthFlowType.login,
            loginData: OtpLoginData(uid: user.uid, idToken: idToken!),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      showAppErrorSnack(context, _mapFirebaseLoginError(e.code));
    } catch (e) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Terjadi kesalahan. Silakan coba lagi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Finalize login tanpa OTP (user tanpa nomor HP).
  Future<void> _finalizeLogin(User user, String idToken) async {
    try {
      final profileResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_seen', true);

      if (profileResponse.statusCode == 200) {
        final data = jsonDecode(profileResponse.body) as Map<String, dynamic>;
        final userData = data['data'] as Map<String, dynamic>? ?? {};
        await prefs.setString('user_id', user.uid);
        await prefs.setString('token', idToken);
        await prefs.setString('user_name', userData['name']?.toString() ?? '');
        await prefs.setString('user_email', userData['email']?.toString() ?? '');
        await prefs.setString('user_phone', userData['phone']?.toString() ?? '');
        await prefs.setString(
          'user_profile_photo_url',
          userData['profilePhotoUrl']?.toString() ?? '',
        );
        await prefs.setString('user_status', userData['status']?.toString() ?? '');
      }

      await NotificationService.instance.syncAfterLogin();

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Gagal memuat profil. Coba lagi.');
    }
  }

  String _mapFirebaseLoginError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email atau password salah.';
      case 'user-disabled':
        return 'Akun ini telah dinonaktifkan. Hubungi support.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti.';
      case 'network-request-failed':
        return 'Koneksi internet bermasalah. Coba lagi.';
      default:
        return 'Login gagal. Silakan coba lagi.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isAnyLoading = _isLoading || authController.isOtpLoading;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF012D1D),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFF012D1D).withValues(alpha: 0.7),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF8EF),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 32,
                    right: 32,
                    top: isKeyboardOpen ? 24 : 40,
                    bottom: isKeyboardOpen
                        ? 16
                        : 40 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Header
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        child: isKeyboardOpen
                            ? const SizedBox(width: double.infinity)
                            : Column(
                                children: [
                                  const Text(
                                    'Hello',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 60,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF012D1D),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Masuk ke akun Anda untuk melanjutkan penjelajahan.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Color(0xFF414844),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                      ),

                      // Email Field
                      _buildLabel('Email'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isAnyLoading,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF012D1D),
                        ),
                        decoration: _inputDecoration('nama@email.com'),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        enabled: !isAnyLoading,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF012D1D),
                        ),
                        decoration: _inputDecoration(
                          'Masukkan password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF717973),
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _isPasswordVisible = !_isPasswordVisible),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Tombol Login
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isAnyLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B5804),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                                const Color(0xFF7B5804).withValues(alpha: 0.6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            elevation: 0,
                          ),
                          child: isAnyLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF012D1D),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        color: const Color(0xFF717973).withValues(alpha: 0.5),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
