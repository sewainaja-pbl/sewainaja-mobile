import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../../app_feedback.dart';
import '../../../core/utils/phone_formatter.dart';
import 'otp_page.dart';

/// Halaman registrasi akun baru.
///
/// Alur:
/// 1. User isi nama, email, password, nomor HP
/// 2. Flutter validasi ke backend (cek duplikat email & phone)
/// 3. Firebase kirim OTP ke nomor HP
/// 4. Navigasi ke OtpPage dengan flowType = register
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validasi form secara lokal sebelum request ke server.
  String? _validateLocally() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      return 'Harap isi semua kolom pendaftaran.';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      return 'Format email tidak valid.';
    }
    if (password.length < 8) {
      return 'Password minimal 8 karakter.';
    }
    if (!PhoneFormatter.isValidIndonesianPhone(phone)) {
      return 'Format nomor HP tidak valid. Gunakan format 08xx atau +62xx.';
    }
    return null;
  }

  Future<void> _handleRegister() async {
    // Validasi lokal terlebih dahulu
    final localError = _validateLocally();
    if (localError != null) {
      showAppErrorSnack(context, localError);
      return;
    }

    final authController = context.read<AuthController>();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phoneE164 = PhoneFormatter.toE164Format(_phoneController.text.trim());

    // Langkah 1: Validasi ke backend (cek duplikat email & phone)
    final isValid = await authController.validateRegistration(
      name: name,
      email: email,
      phone: phoneE164,
      password: password,
    );

    if (!mounted) return;

    if (!isValid) {
      showAppErrorSnack(
        context,
        authController.errorMessage ?? 'Validasi gagal.',
      );
      return;
    }

    // Langkah 2: Kirim OTP ke Firebase
    showAppSuccessSnack(context, 'Mengirim OTP ke $phoneE164...');

    final otpSent = await authController.sendOtp(phoneNumber: phoneE164);

    if (!mounted) return;

    if (!otpSent) {
      showAppErrorSnack(
        context,
        authController.errorMessage ?? 'Gagal mengirim OTP. Coba lagi.',
      );
      return;
    }

    showAppSuccessSnack(context, 'Kode OTP berhasil dikirim!');

    // Langkah 3: Navigasi ke OtpPage dengan data yang diperlukan
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpPage(
          phoneNumber: phoneE164,
          flowType: AuthFlowType.register,
          registerData: OtpRegisterData(
            name: name,
            email: email,
            password: password,
            phone: phoneE164,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool isPassword = false,
    Widget? prefixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
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
              color: const Color(0xFF717973).withValues(alpha: 0.5),
            ),
            prefixIcon: prefixIcon,
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: const Color(0xFF717973),
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  )
                : null,
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
    final isLoading = authController.status == AuthStatus.loading ||
        authController.isOtpLoading;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFF012D1D),
      body: Stack(
        children: [
          // Background
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

          // Form Sheet
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
                      colors: [Colors.black, Colors.transparent],
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
                          height: isKeyboardOpen ? 16 : 40,
                        ),

                        // Tombol back
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: isLoading ? null : () => Navigator.pop(context),
                            child: Icon(
                              Icons.arrow_back,
                              color: isLoading
                                  ? const Color(0xFF012D1D).withValues(alpha: 0.5)
                                  : const Color(0xFF012D1D),
                              size: 24,
                            ),
                          ),
                        ),

                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          child: isKeyboardOpen
                              ? const SizedBox(width: double.infinity, height: 8)
                              : Column(
                                  children: [
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Sign up',
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
                                      'Daftar akun untuk melanjutkan penjelajahan.',
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

                        // Nama
                        _buildInputField(
                          label: 'Nama',
                          hint: 'Nama Lengkap',
                          controller: _nameController,
                          keyboardType: TextInputType.name,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Nomor Telepon
                        _buildInputField(
                          label: 'Nomor Telepon',
                          hint: '8xx xxxx xxxx',
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !isLoading,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'[\d\+\-\s]')),
                          ],
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 8,
                              top: 15,
                              bottom: 15,
                            ),
                            child: Text(
                              '+62',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                color: const Color(0xFF717973)
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        _buildInputField(
                          label: 'Email',
                          hint: 'nama@email.com',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 20),

                        // Password
                        _buildInputField(
                          label: 'Password',
                          hint: 'Minimal 8 karakter',
                          controller: _passwordController,
                          isPassword: true,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 32),

                        // Tombol Sign Up
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B5804),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF7B5804).withValues(alpha: 0.6),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              elevation: 0,
                            ),
                            child: isLoading
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
                                    'Sign Up',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(
                            height: MediaQuery.of(context).padding.bottom),
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
