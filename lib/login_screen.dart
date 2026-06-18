import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/pages/auth/otp_page.dart';
import 'signup_screen.dart';
import 'main_navigation_screen.dart';
import 'api_config.dart';
import 'app_feedback.dart';
import 'notification_service.dart';
import 'forgot_password_screen.dart';
import 'core/utils/phone_formatter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (isError) {
      showAppErrorSnack(context, message);
      return;
    }
    showAppSuccessSnack(context, message);
  }



  /// Simpan sesi ke SharedPreferences lalu navigasi ke home.
  /// Dipakai bila user tidak punya nomor HP (Google login atau admin).
  Future<void> _saveSessionAndNavigate(User user, String idToken) async {
    try {
      final profileResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', idToken);
      await prefs.setString('user_id', user.uid);
      await prefs.setBool('onboarding_seen', true);

      if (profileResponse.statusCode == 200) {
        final respData =
            jsonDecode(profileResponse.body) as Map<String, dynamic>;
        final userData = respData['data'] as Map<String, dynamic>? ?? {};
        await prefs.setString('user_name', userData['name']?.toString() ?? '');
        await prefs.setString('user_email', userData['email']?.toString() ?? '');
        await prefs.setString('user_phone', userData['phone']?.toString() ?? '');
        await prefs.setString(
          'user_profile_photo_url',
          userData['profilePhotoUrl']?.toString() ?? '',
        );
        await prefs.setString(
            'user_status', userData['status']?.toString() ?? '');
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
      _showSnackBar('Gagal memuat profil. Coba lagi.');
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar('Email dan password harus diisi.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Langkah 1: Login Firebase dengan email & password
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      if (!mounted) return;

      final user = userCredential.user;
      if (user == null) {
        _showSnackBar('Login gagal. Silakan coba lagi.');
        return;
      }

      // Langkah 2: Ambil profil dari backend untuk mendapatkan nomor HP
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

      // Jika user belum punya nomor HP, langsung ke home (misal: Google login)
      if (phoneNumber == null || phoneNumber.isEmpty) {
        await _saveSessionAndNavigate(user, idToken!);
        return;
      }

      // Langkah 3: Kirim OTP ke nomor HP user
      final authController = context.read<AuthController>();
      _showSnackBar(
        'Mengirim OTP ke ${PhoneFormatter.maskPhone(phoneNumber)}...',
        isError: false,
      );

      final otpSent = await authController.sendOtp(phoneNumber: phoneNumber);

      if (!mounted) return;

      if (!otpSent) {
        _showSnackBar(
          authController.errorMessage ?? 'Gagal mengirim OTP. Coba lagi.',
        );
        return;
      }

      _showSnackBar('Kode OTP berhasil dikirim!', isError: false);

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
      _showSnackBar(_mapFirebaseLoginError(e.code));
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Sistem Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  void _handleForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isGoogleLoading = authController.status == AuthStatus.loading;
    final isAnyLoading = _isLoading || isGoogleLoading || authController.isOtpLoading;
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
                padding: EdgeInsets.only(
                  top: isKeyboardOpen ? 16 : 24,
                ),
                child: ShaderMask(
                  shaderCallback: (Rect rect) {
                    return const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black,
                        Colors.transparent,
                      ],
                      stops: [0.95, 1.0],
                    ).createShader(rect);
                  },
                  blendMode: BlendMode.dstIn,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: 32,
                      right: 32,
                      bottom: isKeyboardOpen ? 16 : 40,
                    ),
                    child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Daftar akun
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Daftar akun",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2F6743),
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 8 : 16,
                      ),

                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: isKeyboardOpen
                            ? const SizedBox(width: double.infinity)
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    "Hello",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 60,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF012D1D),
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "Masuk ke akun Anda untuk melanjutkan\npenjelajahan.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF414844),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                      ),

                      // Email Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Email",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF012D1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            enabled: !isAnyLoading,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF012D1D),
                            ),
                            decoration: InputDecoration(
                              hintText: "nama@email.com",
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: const Color(
                                  0xFF717973,
                                ).withValues(alpha: 0.25),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 12 : 24,
                      ),

                      // Password Input
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Password",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF012D1D),
                                ),
                              ),
                              GestureDetector(
                                onTap: isAnyLoading
                                    ? null
                                    : _handleForgotPassword,
                                child: Text(
                                  "Forgot password?",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isAnyLoading
                                        ? const Color(0xFF7B5804).withValues(
                                            alpha: 0.55,
                                          )
                                        : const Color(0xFF7B5804),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            enabled: !isAnyLoading,
                            obscureText: true,
                            scrollPadding: const EdgeInsets.only(bottom: 180),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF012D1D),
                            ),
                            decoration: InputDecoration(
                              hintText: "Masukkan password",
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: const Color(
                                  0xFF717973,
                                ).withValues(alpha: 0.25),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 16 : 32,
                      ),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isAnyLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B5804),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF7B5804).withValues(alpha: 0.6),
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading || authController.isOtpLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 12 : 24,
                      ),

                      // Divider
                      Row(
                        children: [
                          const Expanded(
                            child: Divider(color: Color(0xFF717973)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Text(
                              "ATAU LANJUT DENGAN",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF717973),
                              ),
                            ),
                          ),
                          const Expanded(
                            child: Divider(color: Color(0xFF717973)),
                          ),
                        ],
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 12 : 24,
                      ),

                      // Full Width Google Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isAnyLoading ? null : () async {
                            await authController.signInWithGoogle();
                            if (!mounted) return;
                            if (authController.status == AuthStatus.authenticated && authController.userData != null) {
                              // Google login: simpan data dari userData controller
                              final user = FirebaseAuth.instance.currentUser;
                              final idToken = await user?.getIdToken();
                              if (user != null && idToken != null) {
                                await _saveSessionAndNavigate(user, idToken);
                              }
                            } else if (authController.status == AuthStatus.error) {
                               final message = authController.errorMessage ?? 'Gagal login dengan Google';
                               _showSnackBar(message);
                               debugPrint(
                                 'Google login failed | code=${authController.errorCode} | stage=${authController.errorStage} | detail=${authController.errorRawDetail}',
                               );
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFC1C8C2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          child: isGoogleLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/google.png',
                                      width: 14,
                                      height: 14,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Google",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF012D1D),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      // Add safe area spacing at the bottom
                      SizedBox(height: MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
