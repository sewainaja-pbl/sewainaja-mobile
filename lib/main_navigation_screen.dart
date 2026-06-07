import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'categories_screen.dart';
import 'add_product_screen.dart';
import 'chat_screen.dart';
import 'profile_settings_screen.dart';
import 'notification_service.dart';
// Note: Other screens will be imported here as they are created.

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  bool _isSearchActive = false;
  String? _lastProcessedNotificationId;

  late final List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      null,
      null,
      null,
      null,
      null,
    ];
    _screens[0] = _buildScreen(0);
    // Ensure chat area state is set to false initially (Home tab)
    NotificationService.instance.setChatAreaActive(false);
    NotificationService.instance.addListener(_onNotificationReceived);
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_onNotificationReceived);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow underneath the transparent bottom navigation area
      body: Stack(
        children: [
          // 1. MAIN CONTENT AREA (IndexedStack keeps state alive for all screens)
          IndexedStack(
            index: _selectedIndex,
            children: List.generate(
              _screens.length,
              (index) => _screens[index] ?? const SizedBox.shrink(),
            ),
          ),

          // 2. CUSTOM FLOATING BOTTOM NAVBAR
          // Hidden on index 2 (AddProductScreen) and when search is active
          if (_selectedIndex != 2 && !_isSearchActive)
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
                        activeIcon: Icons.grid_view_rounded,
                        inactiveIcon: Icons.grid_view_outlined,
                      ),
                      _buildNavItem(
                        index: 2,
                        activeIcon: Icons.add_box_rounded,
                        inactiveIcon: Icons.add_box_outlined,
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

  void _onNotificationReceived() {
    final service = NotificationService.instance;
    if (service.notifications.isEmpty) return;

    final latest = service.notifications.first;

    // Check if this is a new unread notification and the user is NOT in the chat area
    if (latest.id != _lastProcessedNotificationId && !latest.isRead) {
      _lastProcessedNotificationId = latest.id;

      if (!service.isChatAreaActive) {
        _showInAppNotificationBanner(latest);
      }
    }
  }

  void _showInAppNotificationBanner(AppNotification notification) {
    if (!mounted) return;

    // Clear any active SnackBars to display the new one immediately
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _changeTab(3); // Switch to Chat tab
          },
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFF1B4332),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Color(0xFFFFF8EF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFFF8EF),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFFD5BF87),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Buka',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFF8EF),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFF012D1D),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: 100, // Float above the floating bottom navigation bar
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1B4332), width: 1.5),
        ),
        duration: const Duration(seconds: 4),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  void _changeTab(int index) {
    setState(() {
      _screens[index] ??= _buildScreen(index);
      _selectedIndex = index;
    });
    NotificationService.instance.setChatAreaActive(index == 3);
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
        _changeTab(index);
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

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          onSearchActiveChanged: (active) {
            setState(() => _isSearchActive = active);
          },
          onProfileRequested: () {
            _changeTab(4);
          },
        );
      case 1:
        return CategoriesScreen(
          onBack: () {
            _changeTab(0);
          },
        );
      case 2:
        return AddProductScreen(
          onBack: () {
            _changeTab(0);
          },
        );
      case 3:
        return ChatScreen(
          onBack: () {
            _changeTab(0);
          },
        );
      case 4:
      default:
        return ProfileSettingsScreen(
          onBack: () {
            _changeTab(0);
          },
        );
    }
  }
}
