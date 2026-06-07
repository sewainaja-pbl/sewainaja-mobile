import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';
import 'app_feedback.dart';

class AddPhoneScreen extends StatefulWidget {
  const AddPhoneScreen({super.key});

  @override
  State<AddPhoneScreen> createState() => _AddPhoneScreenState();
}

class _AddPhoneScreenState extends State<AddPhoneScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {bool isError = true}) {
    if (isError) {
      showAppErrorSnack(context, message);
    } else {
      showAppSuccessSnack(context, message);
    }
  }

  void _handleSubmit() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      _showSnackBar('Harap masukkan nomor telepon Anda.');
      return;
    }

    if (phone.length < 9) {
      _showSnackBar('Nomor telepon tidak valid.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    String formattedPhone = phone;
    if (formattedPhone.startsWith('+')) {
      // already formatted
    } else if (formattedPhone.startsWith('62')) {
      formattedPhone = '+$formattedPhone';
    } else if (formattedPhone.startsWith('0')) {
      formattedPhone = '+62${formattedPhone.substring(1)}';
    } else {
      formattedPhone = '+62$formattedPhone';
    }

    // Delay simulated for verification code generation
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Kode OTP berhasil dikirim!', isError: false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationScreen(
            phoneNumber: formattedPhone,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  color: Color(0xFFFFF8EF), // Warna bg_surface
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: isKeyboardOpen ? 16 : 36,
                  bottom: isKeyboardOpen ? 16 : 40,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                                  "Lengkapi Profil",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 32,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF012D1D),
                                    height: 1.1,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Masukkan nomor telepon aktif Anda untuk verifikasi keamanan OTP.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF414844),
                                  ),
                                ),
                                const SizedBox(height: 36),
                              ],
                            ),
                    ),

                    // Phone Input Field
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Nomor Telepon",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          enabled: !_isLoading,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF012D1D),
                          ),
                          decoration: InputDecoration(
                            hintText: "8xx xxxx xxxx",
                            hintStyle: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF717973).withValues(alpha: 0.25),
                            ),
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
                                  color: const Color(0xFF717973).withValues(alpha: 0.25),
                                ),
                              ),
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
                        height: isKeyboardOpen ? 16 : 36,
                      ),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
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
                                "Kirim OTP",
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
