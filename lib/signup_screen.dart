import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'presentation/controllers/auth_controller.dart';
import 'main_navigation_screen.dart';
import 'app_feedback.dart';
import 'notification_service.dart';
import 'otp_verification_screen.dart';
import 'api_config.dart';
import 'add_phone_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  // Controllers & Dynamic State
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
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
      begin: const Offset(0.0, 1.0), // Off-screen bottom
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    // Start animation immediately when screen opens
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Custom SnackBar Premium Style
  void _showSnackBar(String message, {bool isError = true}) {
    if (isError) {
      showAppErrorSnack(context, message);
      return;
    }
    showAppSuccessSnack(context, message);
  }

  Future<void> _saveUserDataAndNavigate(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final token = (data['tokens']?['idToken'] ?? '').toString();
    final user = data['user'] as Map<String, dynamic>? ?? const {};
    if (token.isNotEmpty) {
      await prefs.setString('token', token);
    }
    await prefs.setBool('onboarding_seen', true);
    await prefs.setString('user_id', (user['id'] ?? '').toString());
    await prefs.setString('user_name', (user['name'] ?? '').toString());
    await prefs.setString('user_email', (user['email'] ?? '').toString());
    await prefs.setString('user_phone', (user['phone'] ?? '').toString());
    await prefs.setString(
      'user_profile_photo_url',
      (user['profilePhotoUrl'] ?? '').toString(),
    );
    await prefs.setString('user_status', (user['status'] ?? '').toString());
    await NotificationService.instance.syncAfterLogin();
    if (!mounted) return;
    _showSnackBar('Login berhasil!', isError: false);
    final phoneNum = (user['phone'] ?? '').toString().trim();
    if (phoneNum.isEmpty) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AddPhoneScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );
    }
  }

  void _showGoogleLoginDebugDialog(AuthController authController) {
    final errorMessage =
        authController.errorMessage ?? 'Gagal login dengan Google.';
    final errorCode = authController.errorCode ?? 'UNKNOWN';
    final errorStage = authController.errorStage ?? 'unknown';
    final rawDetail = authController.errorRawDetail?.trim();

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Google Login Gagal',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGoogleErrorRow('Pesan', errorMessage),
                const SizedBox(height: 12),
                _buildGoogleErrorRow('Kode', errorCode),
                const SizedBox(height: 12),
                _buildGoogleErrorRow('Tahap', errorStage),
                if (rawDetail != null && rawDetail.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildGoogleErrorRow('Detail', rawDetail),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Tutup',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF717973),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoogleErrorRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE1DDD6)),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF414844),
            ),
          ),
        ),
      ],
    );
  }

  // Real FireBase SignUp + Store Profile Execution using API
  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Harap isi semua kolom pendaftaran.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String formattedPhone = phone;
    if (formattedPhone.startsWith('+')) {
      // assume already formatted
    } else if (formattedPhone.startsWith('62')) {
      formattedPhone = '+$formattedPhone';
    } else if (formattedPhone.startsWith('0')) {
      formattedPhone = '+62${formattedPhone.substring(1)}';
    } else {
      formattedPhone = '+62$formattedPhone';
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': formattedPhone,
          'isOwner': true,
          'isRenter': true,
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final prefs = await SharedPreferences.getInstance();
        final uid = (data['data']?['uid'] ?? '').toString();
        if (uid.isNotEmpty) {
          await prefs.setString('user_id', uid);
        }
        if (!mounted) return;
        _showSnackBar('Akun berhasil terdaftar!', isError: false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OtpVerificationScreen(),
          ),
        );
      } else {
        _showSnackBar(data['message'] ?? 'Registrasi gagal.');
      }
    } catch (e) {
      _showSnackBar('Sistem Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    Widget? prefixIcon,
    Widget? rightLabel,
    TextInputType? keyboardType,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF012D1D),
              ),
            ),
            ?rightLabel,
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          enabled: enabled,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF012D1D),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF717973).withValues(alpha: 0.25),
            ),
            prefixIcon: prefixIcon,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isGoogleLoading = authController.status == AuthStatus.loading;
    final isAnyLoading = _isLoading || isGoogleLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF012D1D),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(
                    0xFFFFF8EF,
                  ), // Changed to match Login design tokens
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: const EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 24,
                  bottom: 40,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      // Header - Go back to Login
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: isAnyLoading ? null : () {
                            Navigator.pop(context);
                          },
                          child: Icon(
                            Icons.arrow_back,
                            color: isAnyLoading
                                ? const Color(0xFF012D1D).withValues(alpha: 0.5)
                                : const Color(0xFF012D1D),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        "Sign up",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF012D1D),
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Daftar akun anda melanjutkan\npenjelajahan.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF414844),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Inputs
                      _buildInputField(
                        label: "Nama", 
                        hint: "Nama Lengkap",
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        enabled: !isAnyLoading,
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        label: "Nomor Telepom",
                        hint: "8xx xxxx xxxx",
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        enabled: !isAnyLoading,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 8,
                            top: 15,
                            bottom: 15,
                          ),
                          child: Text(
                            "+62",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(
                                0xFF717973,
                              ).withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        label: "Email", 
                        hint: "nama@email.com",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isAnyLoading,
                      ),
                      const SizedBox(height: 24),
                      _buildInputField(
                        label: "Password",
                        hint: "Masukkan password",
                        controller: _passwordController,
                        isPassword: true,
                        enabled: !isAnyLoading,
                      ),
                      const SizedBox(height: 32),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isAnyLoading ? null : _handleSignUp,
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
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

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
                      const SizedBox(height: 24),

                      // Social Login (Google)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isAnyLoading ? null : () async {
                            await authController.signInWithGoogle();
                            if (!mounted) return;
                            if (authController.status == AuthStatus.authenticated && authController.userData != null) {
                               await _saveUserDataAndNavigate(authController.userData!);
                            } else if (authController.status == AuthStatus.error) {
                               final message = authController.errorMessage ?? 'Gagal login dengan Google';
                               final code = authController.errorCode;
                               _showSnackBar(
                                 code != null && code.isNotEmpty
                                     ? '$message [Code: $code]'
                                     : message,
                               );
                               debugPrint(
                                 'Google login failed | code=${authController.errorCode} | stage=${authController.errorStage} | detail=${authController.errorRawDetail}',
                               );
                               _showGoogleLoginDebugDialog(authController);
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
        ],
      ),
    );
  }
}
