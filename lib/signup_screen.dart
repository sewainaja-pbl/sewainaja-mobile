import 'package:flutter/material.dart';
import 'otp_verification_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

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
    super.dispose();
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    bool isPassword = false,
    Widget? prefixIcon,
    Widget? rightLabel,
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
            if (rightLabel != null) rightLabel,
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: isPassword,
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
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF012D1D),
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
                      _buildInputField(label: "Nama", hint: "Nama Lengkap"),
                      const SizedBox(height: 24),
                      _buildInputField(
                        label: "Nomor Telepom",
                        hint: "+62",
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
                      _buildInputField(label: "Email", hint: "nama@email.com"),
                      const SizedBox(height: 24),
                      _buildInputField(
                        label: "Password",
                        hint: "Masukkan password",
                        isPassword: true,
                        rightLabel: GestureDetector(
                          onTap: () {},
                          child: const Text(
                            "Forgot password?",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF7B5804),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Sign Up Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OtpVerificationScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7B5804),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
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

                      // Social Login (Google Only - Full Width)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const OtpVerificationScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Color(0xFFC1C8C2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                          child: Row(
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
