import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // 1. BACKGROUND IMAGE
          // ==========================================
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding1.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // ==========================================
          // 2. GRADIENT OVERLAY
          // ==========================================
          // Layer rectangle fade out warna hitam ke transparan
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black, // #000000
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.6],
                ),
              ),
            ),
          ),

          // ==========================================
          // 3. CONTENT & UI ELEMENTS
          // ==========================================
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  const Text(
                    "Limitless Potential at a Fraction of the Cost.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFF8EF),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subheading
                  const Text(
                    "Nikmati teknologi premium dengan syaratmu sendiri. Sewa apa yang kamu butuhkan, hanya saat kamu membutuhkannya.",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFFFFF8EF),
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Tracker & Next Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tracker
                      Row(
                        children: List.generate(3, (index) {
                          // Active step 1 berarti index 0 yang aktif
                          bool isActive = index == 0;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: isActive ? 32 : 8, // Memanjang jika aktif
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF1B4332) : const Color(0xFFFFF8EF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      
                      // Next Button
                      ElevatedButton(
                        onPressed: () {
                          // TODO: Tambahkan aksi navigasi ke onboarding berikutnya
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4332), // Background
                          foregroundColor: const Color(0xFFFFF8EF), // Text color
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Next",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
