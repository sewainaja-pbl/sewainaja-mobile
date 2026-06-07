import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Semua", "Aktif", "Selesai", "Dibatalkan"];

  final List<Map<String, dynamic>> _dummyHistory = [
    {
      "name": "Sony Camera a6000",
      "owner": "Han so Hee",
      "date_range": "8 Apr - 10 Apr 2025",
      "image": "assets/images/Iklan.jpg",
    },
    {
      "name": "Sony Camera a6000",
      "owner": "Han so Hee",
      "date_range": "8 Mar - 10 Mar 2025",
      "image": "assets/images/Iklan.jpg",
    },
    {
      "name": "Sony Camera a6000",
      "owner": "Han so Hee",
      "date_range": "8 Jan - 10 Jan 2025",
      "image": "assets/images/Iklan.jpg",
    },
    {
      "name": "Sony Camera a6000",
      "owner": "Han so Hee",
      "date_range": "8 Jan - 10 Jan 2025",
      "image": "assets/images/Iklan.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Krem Terang
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDF9F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF012D1D)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "History",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332), // Hijau Medium
          ),
        ),
      ),
      extendBody: true,
      body: Stack(
        children: [
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                int index = entry.key;
                String label = entry.value;
                bool isActive = index == _selectedTabIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                color: isActive
                                    ? const Color(0xFF1B4332)
                                    : const Color(0xFF828282),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (isActive)
                              Container(
                                height: 2,
                                color: const Color(0xFF1B4332),
                              )
                            else
                              const SizedBox(height: 2), // Hindari layout melompat
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),

          // ListView History
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 120.0),
              itemCount: _dummyHistory.length,
              itemBuilder: (context, index) {
                final item = _dummyHistory[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Image Thumbnail
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            image: DecorationImage(
                              image: AssetImage(item["image"]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item["name"],
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600, // Semibold
                                  color: Color(0xFF414844),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Pemilik: ${item['owner']}",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400, // Regular
                                  color: Color(0xFF414844),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_month_rounded,
                                    size: 14,
                                    color: Color(0xFF414844),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item["date_range"],
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400, // Regular
                                      color: Color(0xFF414844),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          height: 75,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF012D1D),
            borderRadius: BorderRadius.circular(40),
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
              _buildNavItem(index: 0, activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined),
              _buildNavItem(index: 1, activeIcon: Icons.grid_view_rounded, inactiveIcon: Icons.grid_view_outlined),
              _buildNavItem(index: 2, activeIcon: Icons.add_box_rounded, inactiveIcon: Icons.add_box_outlined),
              _buildNavItem(index: 3, activeIcon: Icons.chat_bubble_rounded, inactiveIcon: Icons.chat_bubble_outline_rounded),
              _buildNavItem(index: 4, activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData activeIcon, required IconData inactiveIcon}) {
    final bool isActive = 4 == index; // Profile is always active

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          Navigator.pop(context); // Go back to profile screen
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(initialIndex: index),
            ),
            (route) => false,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 55,
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
              key: ValueKey<bool>(isActive),
              color: isActive ? const Color(0xFF012D1D) : const Color(0xFFFFF8EF),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
