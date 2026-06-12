import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'about_app_screen.dart';
import 'app_feedback.dart';
import 'data/repositories/auth_repository.dart';
import 'default_address_setup_screen.dart';
import 'help_center_screen.dart';
import 'login_security_screen.dart';
import 'animated_splash_screen.dart';
import 'notification_settings_screen.dart';
import 'privacy_settings_screen.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthRepository _authRepository = AuthRepository();
  bool _isLoggingOut = false;

  Future<void> _openDefaultLocation() async {
    final result = await Navigator.push<DefaultAddressResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const DefaultAddressSetupScreen(returnSelectionOnSave: true),
      ),
    );

    if (!mounted || result == null) return;
    showAppSuccessSnack(context, 'Lokasi utama berhasil diperbarui.');
  }

  void _openHelpCenter() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
    );
  }

  void _openAboutApp() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AboutAppScreen()),
    );
  }

  void _openNotificationSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
    );
  }

  void _openPrivacySettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacySettingsScreen()),
    );
  }

  void _openLoginSecurity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginSecurityScreen()),
    );
  }

  Future<void> _handleLogout() async {
    if (_isLoggingOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF8EF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          content: const Text(
            'Kamu yakin mau keluar dari akun ini?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF414844),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Batal',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF717973),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoggingOut = true);
    try {
      await _authRepository.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      // Setelah logout, tampilkan onboarding lagi sebelum login ulang.
      await prefs.setBool('onboarding_seen', false);

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AnimatedSplashScreen()),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Logout gagal. Coba lagi sebentar lagi.');
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 82,
        titleSpacing: 24,
        title: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF012D1D),
                size: 28,
              ),
            ),
            const Spacer(),
            const Text(
              'Pengaturan',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFF012D1D),
              ),
            ),
            const Spacer(),
            const SizedBox(width: 28),
          ],
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildSection(
              title: 'Preferensi',
              description:
                  'Atur hal-hal penting yang paling sering kamu butuhkan.',
              items: [
                _SettingsItemData(
                  title: 'Notifikasi',
                  description: 'Atur update sewa, chat, dan pengingat.',
                  icon: Icons.notifications_none_rounded,
                  onTap: _openNotificationSettings,
                ),
                _SettingsItemData(
                  title: 'Lokasi Utama',
                  description: 'Kelola alamat default dan area pencarian.',
                  icon: Icons.location_on_outlined,
                  onTap: _openDefaultLocation,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildSection(
              title: 'Keamanan & Privasi',
              description:
                  'Kontrol akses akun dan perlindungan data pribadimu.',
              items: [
                _SettingsItemData(
                  title: 'Privasi Akun',
                  description:
                      'Kelola visibilitas profil dan informasi publik.',
                  icon: Icons.lock_outline_rounded,
                  onTap: _openPrivacySettings,
                ),
                _SettingsItemData(
                  title: 'Keamanan Login',
                  description: 'Pantau sesi aktif dan proteksi akun.',
                  icon: Icons.shield_outlined,
                  onTap: _openLoginSecurity,
                ),
              ],
            ),
            const SizedBox(height: 22),
            _buildSection(
              title: 'Bantuan',
              description:
                  'Info penting seputar aplikasi dan jalur bantuan tetap enak diakses dari sini.',
              items: [
                _SettingsItemData(
                  title: 'Pusat Bantuan',
                  description: 'FAQ ringkas, panduan penggunaan, dan solusi cepat.',
                  icon: Icons.help_outline_rounded,
                  onTap: _openHelpCenter,
                ),
                _SettingsItemData(
                  title: 'Tentang SewaInAja',
                  description: 'Versi aplikasi, kebijakan, dan informasi layanan.',
                  icon: Icons.info_outline_rounded,
                  onTap: _openAboutApp,
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<_SettingsItemData> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(28),
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
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 14),
              child: _SettingsTile(item: item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: _handleLogout,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _isLoggingOut ? 0.72 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFF3D4D4)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x11000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: _isLoggingOut
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFB42318),
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFB42318),
                      ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB42318),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Keluar dari akun ini dan kembali ke halaman login.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8C4A4A),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFD1A3A3),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final _SettingsItemData item;

  const _SettingsTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4EE),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: const Color(0xFF0E4A31), size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C1C19),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF717973),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFC4C9C4),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItemData {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsItemData({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}
