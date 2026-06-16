import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'presentation/controllers/auth_controller.dart';
import 'presentation/pages/auth/otp_page.dart';
import 'app_feedback.dart';
import 'api_config.dart';
import 'core/utils/phone_formatter.dart';

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
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

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

  /// Sign Up flow OTP:
  /// 1. Validasi input
  /// 2. POST /auth/register ke backend (hanya cek duplikat email & HP)
  /// 3. Kirim OTP via Firebase verifyPhoneNumber
  /// 4. Navigasi ke OtpPage dengan data register
  Future<void> _handleSignUp() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar('Harap isi semua kolom pendaftaran.');
      return;
    }

    // Format nomor HP ke E.164
    final formattedPhone = PhoneFormatter.toE164Format(phone);

    if (!PhoneFormatter.isValidIndonesianPhone(phone)) {
      _showSnackBar('Format nomor HP tidak valid. Contoh: 8120000000');
      return;
    }

    if (password.length < 8) {
      _showSnackBar('Password minimal 8 karakter.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Langkah 1: Validasi duplikat email & HP via backend
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

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final errorCode = data['error']?['code']?.toString() ?? '';
        final apiMessage =
            data['error']?['message']?.toString() ??
            data['message']?.toString() ??
            'Registrasi gagal.';

        // Pesan error yang lebih spesifik berdasarkan kode
        if (errorCode == 'EMAIL_TAKEN') {
          _showSnackBar('Email ini sudah digunakan. Gunakan email lain.');
        } else if (errorCode == 'PHONE_TAKEN') {
          _showSnackBar(
              'Nomor HP ini sudah terdaftar. Gunakan nomor lain atau login.');
        } else {
          _showSnackBar(apiMessage);
        }
        return;
      }

      // Langkah 2: Validasi lolos, kirim OTP ke nomor HP
      final authController = context.read<AuthController>();
      _showSnackBar(
        'Mengirim OTP ke ${PhoneFormatter.maskPhone(formattedPhone)}...',
        isError: false,
      );

      final otpSent = await authController.sendOtp(phoneNumber: formattedPhone);

      if (!mounted) return;

      if (!otpSent) {
        _showSnackBar(
          authController.errorMessage ?? 'Gagal mengirim OTP. Coba lagi.',
        );
        return;
      }

      _showSnackBar('Kode OTP berhasil dikirim!', isError: false);

      // Langkah 3: Navigasi ke OtpPage untuk verifikasi OTP
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpPage(
            phoneNumber: formattedPhone,
            flowType: AuthFlowType.register,
            registerData: OtpRegisterData(
              name: name,
              email: email,
              password: password,
              phone: formattedPhone,
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Sistem Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    EdgeInsets scrollPadding = const EdgeInsets.all(20.0),
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
          scrollPadding: scrollPadding,
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
    final isAnyLoading =
        _isLoading || isGoogleLoading || authController.isOtpLoading;
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 16 : 40,
                      ),
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
                                    "Daftar akun anda untuk melanjutkan\npenjelajahan.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Color(0xFF414844),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                      ),

                      // Inputs
                      _buildInputField(
                        label: "Nama",
                        hint: "Nama Lengkap",
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        enabled: !isAnyLoading,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 12 : 24,
                      ),
                      _buildInputField(
                        label: "Nomor Telepon",
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
                              ).withValues(alpha: 0.5),
                            ),
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 12 : 24,
                      ),
                      _buildInputField(
                        label: "Email",
                        hint: "nama@email.com",
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isAnyLoading,
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 12 : 24,
                      ),
                      _buildInputField(
                        label: "Password",
                        hint: "Masukkan password (min. 8 karakter)",
                        controller: _passwordController,
                        isPassword: true,
                        enabled: !isAnyLoading,
                        scrollPadding: const EdgeInsets.only(bottom: 180),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: isKeyboardOpen ? 16 : 32,
                      ),

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
                                  "Sign Up",
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

                      // Social Login (Google)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: isAnyLoading ? null : () async {
                            await authController.signInWithGoogle();
                            if (!mounted) return;
                            if (authController.status == AuthStatus.authenticated) {
                              // Google register/login berhasil, OtpPage tidak diperlukan
                              // AuthController.signInWithGoogle() sudah handle navigasi
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
          ),
        ],
      ),
    );
  }
}
