import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
        centerTitle: false,
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: const Color(0xFF717973).withValues(alpha: 0.2),
                    width: 1.0,
                  ),
                ),
              ),
              child: const TabBar(
                indicatorColor: Color(0xFF012D1D),
                indicatorWeight: 2.0,
                labelColor: Color(0xFF012D1D),
                unselectedLabelColor: Color(0xFF717973),
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                tabs: [
                  Tab(text: 'Recent activity'),
                  Tab(text: 'Unread'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildRecentActivityTab(),
                  _buildUnreadTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSectionHeader('Today'),
        _buildRecentItem(
          title: 'Seseorang menambahkan ke favorit',
          time: '3 hours ago',
          hasAvatar: false,
        ),
        _buildRecentItem(
          avatarColor: const Color(0xFF005AFF),
          avatarText: 'RD',
          title: 'Robert Doe ',
          subtitle: 'memberikan ulasan di barang anda',
          time: '5 hours ago',
        ),
        _buildSectionHeader('Yesterdaty'),
        _buildRecentItem(
          avatarColor: const Color(0xFFFF6B4A),
          avatarText: 'VA',
          title: 'Robert Doe ',
          subtitle: 'shared the meeting Boctamp Online Course',
          time: '3 hours ago',
        ),
        _buildRecentItem(
          avatarColor: const Color(0xFF282A37),
          avatarText: '',
          title: 'Robert Doe ',
          subtitle: 'shared the meeting Boctamp Online Course',
          time: '3 hours ago',
        ),
        _buildRecentItem(
          avatarColor: const Color(0xFFFFFFFF),
          avatarText: 'PA',
          avatarTextColor: const Color(0xFF000000),
          avatarBorder: true,
          title: 'Pam Aeonas ',
          subtitle: 'shared the meeting Boctamp Online Course',
          time: '3 hours ago',
        ),
        _buildSectionHeader('Week Ago'),
        _buildRecentItem(
          avatarColor: const Color(0xFFFF6B4A),
          avatarText: 'VA',
          title: 'Robert Doe ',
          subtitle: 'shared the meeting Boctamp Online Course',
          time: '3 hours ago',
        ),
        _buildRecentItem(
          avatarColor: const Color(0xFF282A37),
          avatarText: '',
          title: 'Robert Doe ',
          subtitle: 'shared the meeting Boctamp Online Course',
          time: '3 hours ago',
        ),
        _buildRecentItem(
          avatarColor: const Color(0xFFFFFFFF),
          avatarText: 'PA',
          avatarTextColor: const Color(0xFF000000),
          avatarBorder: true,
          title: 'Pam Aeonas ',
          subtitle: 'shared the meeting Boctamp Online Course',
          time: '3 hours ago',
        ),
        _buildSectionHeader('Year Ago'),
        _buildRecentItem(
          avatarColor: const Color(0xFFFF6B4A),
          avatarText: 'VA',
          title: 'Robert Doe ',
          subtitle: 'shared the meeting Boctamp Online Course',
          time: '3 hours ago',
        ),
      ],
    );
  }

  Widget _buildUnreadTab() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSectionHeader('Today'),
        _buildUnreadItem(
          avatarText: 'RD',
          title: 'Aminah',
          subtitle: 'Permintaan sewa',
          time: '3 hours ago',
        ),
        _buildUnreadItem(
          avatarText: 'RR',
          title: 'Chat dari Ryan Reynolds',
          subtitle: 'Barangnya untuk hari minggu ready gak?',
          time: '3 hours ago',
        ),
        _buildSectionHeader('Yesterdaty'),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      color: const Color(0xFFFDF9F4),
      padding: const EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: Color(0xFF000000),
        ),
      ),
    );
  }

  // --- RECENT ACTIVITY ITEM ---
  Widget _buildRecentItem({
    Color? avatarColor,
    String? avatarText,
    Color avatarTextColor = Colors.white,
    bool avatarBorder = false,
    bool hasAvatar = true,
    required String title,
    String subtitle = '',
    required String time,
  }) {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      margin: const EdgeInsets.only(bottom: 2), // jarak kecil sebagai pemisah
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAvatar) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: avatarColor,
                shape: BoxShape.circle,
                border: avatarBorder ? Border.all(color: const Color(0xFFECEDF2), width: 1) : null,
              ),
              alignment: Alignment.center,
              child: Text(
                avatarText ?? '',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: avatarTextColor,
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Color(0xFF282A37),
                    ),
                    children: [
                      TextSpan(
                        text: title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                        text: subtitle,
                        style: const TextStyle(fontWeight: FontWeight.w400),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF515978),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UNREAD ITEM ---
  Widget _buildUnreadItem({
    required String avatarText,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      color: const Color(0xFFF6F7F9),
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFF282A37),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              avatarText,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF282A37),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF515978),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF717973),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Color(0xFF012D1D),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
