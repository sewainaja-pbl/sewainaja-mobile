import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/custom_app_bar.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  static const String _keyAllNotifications = 'notif_all_enabled';
  static const String _keyRentalUpdates = 'notif_rental_updates';
  static const String _keyChatMessages = 'notif_chat_messages';
  static const String _keyReminders = 'notif_reminders';
  static const String _keyPromotions = 'notif_promotions';

  bool _isLoading = true;
  bool _allNotifications = true;
  bool _rentalUpdates = true;
  bool _chatMessages = true;
  bool _reminders = true;
  bool _promotions = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _allNotifications = prefs.getBool(_keyAllNotifications) ?? true;
      _rentalUpdates = prefs.getBool(_keyRentalUpdates) ?? true;
      _chatMessages = prefs.getBool(_keyChatMessages) ?? true;
      _reminders = prefs.getBool(_keyReminders) ?? true;
      _promotions = prefs.getBool(_keyPromotions) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _persist(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _toggleAll(bool value) async {
    setState(() {
      _allNotifications = value;
      if (!value) {
        _rentalUpdates = false;
        _chatMessages = false;
        _reminders = false;
        _promotions = false;
      }
    });

    await _persist(_keyAllNotifications, value);
    if (!value) {
      await _persist(_keyRentalUpdates, false);
      await _persist(_keyChatMessages, false);
      await _persist(_keyReminders, false);
      await _persist(_keyPromotions, false);
    }
  }

  Future<void> _toggleChild({
    required String key,
    required bool value,
    required void Function() applyState,
  }) async {
    setState(() {
      applyState();
      _allNotifications =
          _rentalUpdates || _chatMessages || _reminders || _promotions;
    });
    await _persist(key, value);
    await _persist(_keyAllNotifications, _allNotifications);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: const CustomAppBar(
        title: 'Notifikasi',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF012D1D),
              ),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 22),
                  _buildSection(
                    title: 'Kontrol Utama',
                    description:
                        'Tentukan apakah kamu ingin tetap menerima notifikasi dari aplikasi.',
                    children: [
                      _buildSwitchTile(
                        title: 'Aktifkan semua notifikasi',
                        subtitle:
                            'Matikan opsi ini kalau kamu ingin menenangkan semua notifikasi sekaligus.',
                        value: _allNotifications,
                        onChanged: _toggleAll,
                        icon: Icons.notifications_active_outlined,
                        highlight: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildSection(
                    title: 'Jenis Notifikasi',
                    description:
                        'Pilih update yang ingin tetap kamu terima sesuai kebutuhanmu.',
                    children: [
                      _buildSwitchTile(
                        title: 'Update sewa',
                        subtitle:
                            'Info status permintaan, persetujuan pemilik, dan perubahan transaksi.',
                        value: _rentalUpdates,
                        enabled: _allNotifications,
                        onChanged: (value) {
                          _toggleChild(
                            key: _keyRentalUpdates,
                            value: value,
                            applyState: () => _rentalUpdates = value,
                          );
                        },
                        icon: Icons.inventory_2_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Pesan chat',
                        subtitle:
                            'Pesan baru dari penyewa atau pemilik barang yang perlu kamu respon.',
                        value: _chatMessages,
                        enabled: _allNotifications,
                        onChanged: (value) {
                          _toggleChild(
                            key: _keyChatMessages,
                            value: value,
                            applyState: () => _chatMessages = value,
                          );
                        },
                        icon: Icons.chat_bubble_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Pengingat',
                        subtitle:
                            'Pengingat tenggat sewa, jadwal serah terima, dan aktivitas penting lainnya.',
                        value: _reminders,
                        enabled: _allNotifications,
                        onChanged: (value) {
                          _toggleChild(
                            key: _keyReminders,
                            value: value,
                            applyState: () => _reminders = value,
                          );
                        },
                        icon: Icons.alarm_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Info promo dan kabar aplikasi',
                        subtitle:
                            'Kabar fitur baru, promo, dan informasi ringan seputar aplikasi.',
                        value: _promotions,
                        enabled: _allNotifications,
                        onChanged: (value) {
                          _toggleChild(
                            key: _keyPromotions,
                            value: value,
                            applyState: () => _promotions = value,
                          );
                        },
                        icon: Icons.local_offer_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildFootnoteCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    final activeCount = [
      _rentalUpdates,
      _chatMessages,
      _reminders,
      _promotions,
    ].where((item) => item).length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atur ritme notifikasi biar tetap relevan.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _allNotifications
                ? '$activeCount kategori notifikasi aktif saat ini.'
                : 'Semua notifikasi sedang kamu nonaktifkan.',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
            description,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    bool enabled = true,
    bool highlight = false,
  }) {
    final tileColor = enabled
        ? (highlight ? const Color(0xFFEAF4EE) : const Color(0xFFF9F7F3))
        : const Color(0xFFF1EFEA);
    final textColor = enabled
        ? const Color(0xFF1C1C19)
        : const Color(0xFF9EA39D);
    final subtitleColor = enabled
        ? const Color(0xFF717973)
        : const Color(0xFFAEB3AE);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: enabled ? 1 : 0.72,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tileColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF0E4A31)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: value,
              onChanged: enabled ? onChanged : null,
              activeThumbColor: const Color(0xFF012D1D),
              activeTrackColor: const Color(0xFFBFD8CA),
              inactiveThumbColor: const Color(0xFFB5BBB6),
              inactiveTrackColor: const Color(0xFFE0E2DD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFootnoteCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Preferensi ini masih disimpan di perangkat, jadi kamu bisa atur ritme notifikasi tanpa mengubah data akun utama.',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          height: 1.55,
          fontWeight: FontWeight.w500,
          color: Color(0xFF717973),
        ),
      ),
    );
  }
}
