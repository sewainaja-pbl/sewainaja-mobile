import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'notification_service.dart';
import 'rental_request_screen.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const AppNotification _pinnedDummyNotification = AppNotification(
    id: 'dummy-feature-placeholder',
    title: 'Permintaan sewa baru',
    message:
        'Aminah mengajukan sewa untuk Sony a6000 pada 14-16 Juni. Dummy ini sengaja dipin di atas buat jalur fitur yang nanti dilanjutin temanmu.',
    timeLabel: 'Baru saja',
    category: 'Sewa',
    initials: 'AM',
    isRead: false,
    highlight: true,
    isDummy: true,
    isPinned: true,
    type: 'request',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<NotificationService>().fetchNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationService>(
      builder: (context, notificationService, _) {
        final allItems = [
          _pinnedDummyNotification,
          ...notificationService.notifications,
        ];
        final unreadItems = allItems
            .where((item) => item.isDummy || !item.isRead)
            .toList();

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
            actions: [
              if (notificationService.unreadCount > 0)
                TextButton(
                  onPressed: notificationService.markAllAsRead,
                  child: const Text(
                    'Baca semua',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ),
            ],
          ),
          body: DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  padding: const EdgeInsets.all(4),
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
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      Tab(text: 'Semua'),
                      Tab(text: 'Belum dibaca'),
                    ],
                  ),
                ),
                if (notificationService.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                    child: _InfoBanner(
                      message: notificationService.errorMessage!,
                    ),
                  ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _NotificationList(
                        title: 'Hari ini',
                        subtitle:
                            'Dummy yang dipin tetap paling atas, lalu update notifikasi akunmu muncul di bawahnya.',
                        items: allItems,
                        isLoading: notificationService.isLoading,
                        onRefresh: notificationService.fetchNotifications,
                        onTap: _handleNotificationTap,
                      ),
                      _NotificationList(
                        title: 'Butuh perhatian',
                        subtitle:
                            'Notifikasi yang belum dibaca tetap dikumpulkan di sini supaya gampang dicek cepat.',
                        items: unreadItems,
                        isLoading: notificationService.isLoading,
                        onRefresh: notificationService.fetchNotifications,
                        onTap: _handleNotificationTap,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleNotificationTap(AppNotification item) async {
    if (!item.isDummy && !item.isRead) {
      await context.read<NotificationService>().markAsRead(item.id);
    }

    if (!mounted) {
      return;
    }

    if (item.type == 'request') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const RentalRequestScreen()),
      );
      return;
    }

    if (item.isDummy) {
      _showDummyDetail(context, item);
      return;
    }

    _showNotificationDetail(context, item);
  }

  void _showDummyDetail(BuildContext context, AppNotification item) {
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
              if (item.imageUrl != null) ...[
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      cacheWidth: 400, // Optimize memory for detail sheet
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF1EDE8),
                        alignment: Alignment.center,
                        child: const Text(
                          'Gambar notifikasi gagal dimuat',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF717973),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
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
                    _DetailRow(label: 'Status', value: 'Dummy pinned'),
                    SizedBox(height: 10),
                    _DetailRow(
                      label: 'Tujuan',
                      value:
                          'Slot placeholder untuk flow lanjutan yang nanti disambung temanmu.',
                    ),
                    SizedBox(height: 10),
                    _DetailRow(
                      label: 'Catatan',
                      value: 'Kartu ini sengaja selalu tampil paling atas.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
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
                    'Sip, lanjut nanti',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationDetail(BuildContext context, AppNotification item) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DetailRow(label: 'Kategori', value: item.category),
                    const SizedBox(height: 10),
                    _DetailRow(label: 'Waktu', value: item.timeLabel),
                    if (item.type != null) ...[
                      const SizedBox(height: 10),
                      _DetailRow(label: 'Tipe', value: item.type!),
                    ],
                    if (item.transactionId != null) ...[
                      const SizedBox(height: 10),
                      _DetailRow(
                        label: 'Transaksi',
                        value: item.transactionId!,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
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
                    'Tutup',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationList extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<AppNotification> items;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final ValueChanged<AppNotification> onTap;

  const _NotificationList({
    required this.title,
    required this.subtitle,
    required this.items,
    required this.isLoading,
    required this.onRefresh,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF012D1D)),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF012D1D),
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        itemCount: items.isEmpty ? 4 : items.length + 3,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF012D1D),
              ),
            );
          }
          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF717973),
                ),
              ),
            );
          }
          if (index == 2) {
            return const SizedBox(height: 12);
          }
          final itemIndex = index - 3;
          if (items.isEmpty) {
            return const _EmptyState();
          }
          final item = items[itemIndex];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _NotificationCard(item: item, onTap: () => onTap(item)),
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback onTap;

  const _NotificationCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: item.highlight ? const Color(0xFFEAF4EE) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: item.highlight
                ? const Color(0xFFCDE2D6)
                : const Color(0xFFF0EBE4),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0E000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.highlight
                    ? const Color(0xFF0E4A31)
                    : const Color(0xFFF4F1EB),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                item.initials,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: item.highlight
                      ? Colors.white
                      : const Color(0xFF012D1D),
                ),
              ),
            ),
            const SizedBox(width: 12),
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
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C1C19),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _NotificationBadge(label: item.category),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.message,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF717973),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.imageUrl != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: SizedBox(
                        height: 96,
                        width: double.infinity,
                        child: Image.network(
                          item.imageUrl!,
                          fit: BoxFit.cover,
                          cacheHeight: 150, // Optimize image memory footprint
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: const Color(0xFFF4F1EB),
                                alignment: Alignment.center,
                                child: const Text(
                                  'Gambar tidak tersedia',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF717973),
                                  ),
                                ),
                              ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        item.timeLabel,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF717973),
                        ),
                      ),
                      if (item.isPinned) ...[
                        const SizedBox(width: 10),
                        const Icon(
                          Icons.push_pin_rounded,
                          size: 14,
                          color: Color(0xFF012D1D),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Pinned',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                      ] else if (item.highlight) ...[
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
                            fontSize: 11,
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
}

class _NotificationBadge extends StatelessWidget {
  final String label;

  const _NotificationBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Color(0xFF012D1D),
        ),
      ),
    );
  }
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

class _InfoBanner extends StatelessWidget {
  final String message;

  const _InfoBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        message,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF7B5804),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.notifications_none_rounded,
            size: 42,
            color: Color(0xFF9EA39D),
          ),
          SizedBox(height: 12),
          Text(
            'Belum ada notifikasi lain saat ini.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF717973),
            ),
          ),
        ],
      ),
    );
  }
}
