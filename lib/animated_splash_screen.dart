import 'package:flutter/material.dart';
import 'package:sewainaja/onboarding_screen.dart'; // Import OnboardingScreen

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen> {
  // ===========================================================================
  // STATE ANIMASI
  // ===========================================================================

  // Fase 0: Fade in background radial gradient dari black screen
  bool _startBackgroundFade = false;

  // Fase 1: Mengontrol logo & teks muncul dari bawah dan fade in ke tengah
  bool _startStep1 = false;

  // Fase 2: Mengontrol teks merapatkan spasi antar huruf
  bool _startStep2 = false;

  @override
  void initState() {
    super.initState();
    _startAnimationSequence();
  }

  /// Fungsi untuk menjalankan urutan animasi sesuai dengan spec V3
  void _startAnimationSequence() async {
    // ---------------------------------------------------------
    // STEP 0: Delay 1 Detik di Black Screen & Fade in Background
    // ---------------------------------------------------------
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _startBackgroundFade = true;
      });
    }

    // Tunggu background fade in selesai (misal 500ms) + jeda sejenak (100ms) = 600ms
    await Future.delayed(const Duration(milliseconds: 600));

    // ---------------------------------------------------------
    // STEP 1: rise_and_fade (Logo & Teks muncul dari bawah)
    // ---------------------------------------------------------
    if (mounted) {
      setState(() {
        _startStep1 = true;
      });
    }

    // Tunggu animasi step 1 selesai (800ms) + delay 200ms = 1000ms
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() {
        _startStep2 = true;
      });
    }

    // ---------------------------------------------------------
    // STEP 3: Navigate to Onboarding
    // ---------------------------------------------------------
    // Tunggu animasi step 2 selesai (500ms) + delay navigasi (1000ms) = 1500ms
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      // Ganti Scaffold dummy dengan OnboardingScreen yang sebenarnya
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const OnboardingScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Awalnya black screen
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ==========================================
          // BACKGROUND: Fade in Radial Gradient
          // ==========================================
          AnimatedOpacity(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
            opacity: _startBackgroundFade ? 1.0 : 0.0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Color(0xFF1B4332), // Tengah
                    Color(0xFF012D1D), // Pinggir
                  ],
                  stops: [0.0, 1.0],
                ),
              ),
            ),
          ),

          // ==========================================
          // KONTEN UTAMA (LOGO & TEKS)
          // ==========================================
          SafeArea(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.0, end: _startStep1 ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * value),
                      child: Transform.translate(
                        offset: Offset(0.0, (1.0 - value) * 100.0),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ==========================================
                    // KOMPONEN: LOGO IMAGE
                    // ==========================================
                    Image.asset(
                      'assets/images/logo.png',
                      width: 250,
                      height: 250,
                    ),

                    // ==========================================
                    // KOMPONEN: TEXT TITLE (RichText)
                    // ==========================================
                    // Menggunakan Transform.translate dengan nilai Y negatif
                    // agar teks ditarik ke atas mendekati logo, mengabaikan padding bawaan gambar
                    Transform.translate(
                      offset: const Offset(0, -15),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(
                          begin: 25.0,
                          end: _startStep2 ? 0.0 : 25.0,
                        ),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                        builder: (context, currentLetterSpacing, child) {
                          return RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontFamily: 'BebasNeue',
                                fontSize: 47,
                                letterSpacing: currentLetterSpacing,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'SEWAIN',
                                  style: TextStyle(color: Color(0xFFFFF8EF)),
                                ),
                                TextSpan(
                                  text: 'AJA',
                                  style: TextStyle(color: Color(0xFFD5BF87)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
