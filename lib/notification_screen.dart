import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  static const List<_InboxNotification> _recentNotifications = [
    _InboxNotification(
      title: 'Permintaan sewa baru',
      message:
          'Aminah mengajukan sewa untuk Sony a6000 pada 14-16 Juni. Cek detailnya sebelum kamu respon.',
      time: 'Baru saja',
      category: 'Sewa',
      initials: 'AM',
      highlight: true,
    ),
    _InboxNotification(
      title: 'Pesan baru masuk',
      message:
          'Ryan menanyakan apakah barang masih tersedia untuk akhir pekan ini.',
      time: '12 menit lalu',
      category: 'Chat',
      initials: 'RY',
    ),
    _InboxNotification(
      title: 'Pengingat pengembalian',
      message:
          'Sewa kamera Fujifilm X-T30 akan selesai besok pukul 10.00.',
      time: '1 jam lalu',
      category: 'Pengingat',
      initials: 'RM',
    ),
  ];

  static const List<_InboxNotification> _unreadNotifications = [
    _InboxNotification(
      title: 'Permintaan sewa baru',
      message:
          'Aminah mengajukan sewa untuk Sony a6000 pada 14-16 Juni. Buka sekarang untuk lihat detail permintaannya.',
      time: 'Baru saja',
      category: 'Sewa',
      initials: 'AM',
      highlight: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Notifikasi',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EDE8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Color(0xFF012D1D),
                unselectedLabelColor: Color(0xFF717973),
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Semua'),
                  Tab(text: 'Belum dibaca'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _NotificationList(
                    title: 'Hari ini',
                    subtitle: 'Update terbaru yang paling relevan buat kamu.',
                    items: _recentNotifications,
                  ),
                  _NotificationList(
                    title: 'Butuh perhatian',
                    subtitle:
                        'Notifikasi yang belum kamu buka dan sebaiknya dicek lebih dulu.',
                    items: _unreadNotifications,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_InboxNotification> items;

  const _NotificationList({
    required this.title,
    required this.subtitle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            height: 1.5,
            fontWeight: FontWeight.w500,
            color: Color(0xFF717973),
          ),
        ),
        const SizedBox(height: 18),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _NotificationCard(item: item),
            )),
      ],
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final _InboxNotification item;

  const _NotificationCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showNotificationDetail(context, item),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.highlight ? const Color(0xFFEAF4EE) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: item.highlight
                ? const Color(0xFFCDE2D6)
                : const Color(0xFFF0EBE4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.highlight
                    ? const Color(0xFF0E4A31)
                    : const Color(0xFFF4F1EB),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                item.initials,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      item.highlight ? Colors.white : const Color(0xFF012D1D),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C19),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _NotificationBadge(label: item.category),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.55,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF717973),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        item.time,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF717973),
                        ),
                      ),
                      if (item.highlight) ...[
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFF012D1D),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Baru',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationDetail(BuildContext context, _InboxNotification item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8EF),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7D2C9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                item.title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF012D1D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.message,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  height: 1.55,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF717973),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Pemohon', value: 'Aminah'),
                    SizedBox(height: 10),
                    _DetailRow(label: 'Barang', value: 'Sony a6000'),
                    SizedBox(height: 10),
                    _DetailRow(label: 'Durasi', value: '14-16 Juni'),
                    SizedBox(height: 10),
                    _DetailRow(label: 'Status', value: 'Menunggu respon'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF012D1D),
                        side: const BorderSide(color: Color(0xFFBFC8C1)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Nanti saja',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF012D1D),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Lihat ringkasan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationBadge extends StatelessWidget {
  final String label;

  const _NotificationBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF012D1D),
        ),
      ),
    );
  }
}

class _InboxNotification {
  final String title;
  final String message;
  final String time;
  final String category;
  final String initials;
  final bool highlight;

  const _InboxNotification({
    required this.title,
    required this.message,
    required this.time,
    required this.category,
    required this.initials,
    this.highlight = false,
  });
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
        ),
      ],
    );
  }
}
