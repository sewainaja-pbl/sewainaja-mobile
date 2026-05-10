import 'package:flutter/material.dart';
import 'home_screen.dart';
// Note: Other screens will be imported here as they are created.

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // List of screens to be displayed in the IndexedStack
  final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(body: Center(child: Text("Category Screen"))), // Placeholder
    const Scaffold(body: Center(child: Text("Add Listing Screen"))), // Placeholder
    const Scaffold(body: Center(child: Text("Chat Screen"))), // Placeholder
    const Scaffold(body: Center(child: Text("Profile Screen"))), // Placeholder
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow underneath the transparent bottom navigation area
      body: Stack(
        children: [
          // 1. MAIN CONTENT AREA (IndexedStack keeps state alive for all screens)
          IndexedStack(
            index: _selectedIndex,
            children: _screens,
          ),

          // 2. CUSTOM FLOATING BOTTOM NAVBAR
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                height: 75,
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D), // ID: '201:2650' Background
                  borderRadius: BorderRadius.circular(40), // Pill Shape
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      index: 0,
                      activeIcon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                    ),
                    _buildNavItem(
                      index: 1,
                      activeIcon: Icons.category_rounded,
                      inactiveIcon: Icons.category_outlined,
                    ),
                    _buildNavItem(
                      index: 2,
                      activeIcon: Icons.add_circle_rounded,
                      inactiveIcon: Icons.add_circle_outline_rounded,
                    ),
                    _buildNavItem(
                      index: 3,
                      activeIcon: Icons.chat_bubble_rounded,
                      inactiveIcon: Icons.chat_bubble_outline_rounded,
                    ),
                    _buildNavItem(
                      index: 4,
                      activeIcon: Icons.person_rounded,
                      inactiveIcon: Icons.person_outline_rounded,
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

  // Helper widget to build each navigation item
  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final bool isActive = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque, // Ensures the entire bounding box is clickable
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 55, // Size adjusted to fit 5 items comfortably within padding
        height: 55,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF8EF) : const Color(0xFF1B4332),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Icon(
              isActive ? activeIcon : inactiveIcon,
              key: ValueKey<bool>(isActive), // Force animated switcher to transition when icon changes
              color: isActive ? const Color(0xFF012D1D) : const Color(0xFFFFF8EF),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
