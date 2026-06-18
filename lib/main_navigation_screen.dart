import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'home_screen.dart';
import 'categories_screen.dart';
import 'add_product_screen.dart';
import 'chat_screen.dart';
import 'profile_settings_screen.dart';
import 'notification_service.dart';
import 'widgets/pressable_scale.dart';
import 'api_config.dart';
import 'auth_session_service.dart';
import 'return_evidence_screen.dart';
import 'owner_return_evidence_screen.dart';
import 'core/services/gps_tracking_service.dart';
// Note: Other screens will be imported here as they are created.

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  final GlobalKey<HomeScreenState> _homeKey = GlobalKey<HomeScreenState>();
  int _selectedIndex = 0;
  bool _isSearchActive = false;
  String? _lastProcessedNotificationId;

  late final List<Widget?> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      null,
      null,
      null,
      null,
      null,
    ];
    _screens[_selectedIndex] = _buildScreen(_selectedIndex);
    // Ensure chat area state is set to false initially (Home tab)
    NotificationService.instance.setChatAreaActive(false);
    NotificationService.instance.addListener(_onNotificationReceived);
    
    // Initialize GPS Tracking Service
    GpsTrackingService().initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingRatings();
    });
  }

  @override
  void dispose() {
    NotificationService.instance.removeListener(_onNotificationReceived);
    super.dispose();
  }

  Future<void> _checkPendingRatings() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions?status=waiting_rating'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] is List) {
          final transactions = body['data'] as List;
          for (var trans in transactions) {
            final hasUserRated = trans['hasUserRated'] ?? false;
            if (!hasUserRated) {
              final transactionId = trans['id']?.toString() ?? '';
              final renterId = trans['renterId']?.toString() ?? '';
              final ownerId = trans['ownerId']?.toString() ?? '';

              String itemName = 'Barang Sewaan';
              if (trans['details'] != null && (trans['details'] as List).isNotEmpty) {
                itemName = trans['details'][0]['itemNameSnapshot']?.toString() ?? 'Barang Sewaan';
              } else {
                final detailResponse = await http.get(
                  Uri.parse('${ApiConfig.baseUrl}/transactions/$transactionId'),
                  headers: headers,
                );
                if (detailResponse.statusCode == 200) {
                  final detailBody = jsonDecode(detailResponse.body);
                  if (detailBody['success'] == true && detailBody['data'] != null) {
                    final detailsList = detailBody['data']['details'] as List?;
                    if (detailsList != null && detailsList.isNotEmpty) {
                      itemName = detailsList[0]['itemNameSnapshot']?.toString() ?? 'Barang Sewaan';
                    }
                  }
                }
              }

              if (mounted) {
                if (currentUser.uid == renterId) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReturnEvidenceScreen(
                        transactionId: transactionId,
                        itemName: itemName,
                        isForced: true,
                      ),
                    ),
                  );
                  _checkPendingRatings();
                } else if (currentUser.uid == ownerId) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OwnerReturnEvidenceScreen(
                        transactionId: transactionId,
                        itemName: itemName,
                        isForced: true,
                      ),
                    ),
                  );
                  _checkPendingRatings();
                }
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking pending ratings: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows content to flow underneath the transparent bottom navigation area
      body: Stack(
        children: [
          // 1. MAIN CONTENT AREA (Stack with smooth cross-fade tab transitions)
          Stack(
            children: List.generate(
              _screens.length,
              (index) {
                final screen = _screens[index];
                if (screen == null) return const SizedBox.shrink();
                final bool isActive = _selectedIndex == index;
                return IgnorePointer(
                  ignoring: !isActive,
                  child: TabScreenWrapper(
                    isActive: isActive,
                    duration: const Duration(milliseconds: 240),
                    child: screen,
                  ),
                );
              },
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

    // We no longer show a SnackBar banner because flutter_local_notifications already
    // displays a system heads-up notification in the foreground.
    if (latest.id != _lastProcessedNotificationId && !latest.isRead) {
      _lastProcessedNotificationId = latest.id;
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

    return PressableScale(
      onTap: () {
        if (isActive && index == 0) {
          _homeKey.currentState?.scrollToTop();
        } else {
          _changeTab(index);
        }
      },
      scaleFactor: 0.95, // Gentle press effect for satisfying tap feel
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
          key: _homeKey,
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

/// Widget wrapper khusus yang menonaktifkan Ticker (animasi) dan melompati Layout/Paint
/// untuk tab screen yang sedang tidak aktif di background menggunakan TickerMode & Offstage.
/// Transisi fade-out tetap berjalan lancar hingga selesai sebelum Offstage diaktifkan.
class TabScreenWrapper extends StatefulWidget {
  final Widget child;
  final bool isActive;
  final Duration duration;

  const TabScreenWrapper({
    super.key,
    required this.child,
    required this.isActive,
    required this.duration,
  });

  @override
  State<TabScreenWrapper> createState() => _TabScreenWrapperState();
}

class _TabScreenWrapperState extends State<TabScreenWrapper> {
  late bool _visible;

  @override
  void initState() {
    super.initState();
    _visible = widget.isActive;
  }

  @override
  void didUpdateWidget(TabScreenWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive) {
      _visible = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !_visible,
      child: AnimatedOpacity(
        opacity: widget.isActive ? 1.0 : 0.0,
        duration: widget.duration,
        curve: Curves.easeInOut,
        onEnd: () {
          if (!widget.isActive && mounted) {
            setState(() {
              _visible = false;
            });
          }
        },
        child: widget.child,
      ),
    );
  }
}
