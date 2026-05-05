import 'package:flutter/material.dart';
import 'login_screen.dart';

class OnboardingItem {
  final String imagePath;
  final String title;
  final String subtitle;
  final String buttonText;
  final double titleFontSize;
  final FontWeight titleFontWeight;

  OnboardingItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    this.titleFontSize = 32,
    this.titleFontWeight = FontWeight.bold,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _onboardingItems = [
    OnboardingItem(
      imagePath: 'assets/images/onboarding1.jpg',
      title: 'Limitless Potential at a Fraction of the Cost.',
      subtitle: 'Nikmati teknologi premium dengan syaratmu sendiri. Sewa apa yang kamu butuhkan, hanya saat kamu membutuhkannya.',
      buttonText: 'Next',
      titleFontSize: 32,
      titleFontWeight: FontWeight.bold,
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding2.jpg',
      title: 'MAXIMIZE YOUR CRAFT, MINIMIZE YOUR SPEND.',
      subtitle: 'Selesaikan proyek impianmu tanpa harus membeli alat baru. Temukan perkakas berkualitas tinggi langsung dari komunitas di sekitarmu.',
      buttonText: 'Next',
      titleFontSize: 32,
      titleFontWeight: FontWeight.w700,
    ),
    OnboardingItem(
      imagePath: 'assets/images/onboarding3.jpg',
      title: 'ELEVATE YOUR STYLE, FREE YOUR CLOSET.',
      subtitle: 'Tampil memukau di setiap momen tanpa menumpuk pakaian. Sewa outfit eksklusif hanya untuk acara spesialmu, kapan pun kamu butuh.',
      buttonText: 'Lets Get Started',
      titleFontSize: 40,
      titleFontWeight: FontWeight.w600,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNextPressed() {
    if (_currentPage < _onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ==========================================
          // 1. BACKGROUND IMAGES (PAGEVIEW)
          // ==========================================
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              itemCount: _onboardingItems.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _onboardingItems[index].imagePath,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),

          // ==========================================
          // 2. GRADIENT OVERLAY
          // ==========================================
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black,
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
                  // Heading with animation transition
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Align(
                      key: ValueKey<int>(_currentPage),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _onboardingItems[_currentPage].title,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: _onboardingItems[_currentPage].titleFontSize,
                          fontWeight: _onboardingItems[_currentPage].titleFontWeight,
                          color: const Color(0xFFFFF8EF),
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Subheading with animation transition
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Align(
                      key: ValueKey<int>(_currentPage),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _onboardingItems[_currentPage].subtitle,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFFFFF8EF),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Tracker & Next Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Tracker
                      Row(
                        children: List.generate(_onboardingItems.length, (index) {
                          bool isActive = _currentPage == index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: isActive ? 32 : 8,
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF1B4332) : const Color(0xFFFFF8EF),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                      
                      // Next Button
                      ElevatedButton(
                        onPressed: _onNextPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B4332),
                          foregroundColor: const Color(0xFFFFF8EF),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30), // Updated to 30px from Figma
                          ),
                          elevation: 0,
                        ),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _onboardingItems[_currentPage].buttonText,
                            key: ValueKey<String>(_onboardingItems[_currentPage].buttonText),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
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
