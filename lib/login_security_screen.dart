import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/custom_app_bar.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  static const String _keyLoginAlerts = 'security_login_alerts';
  static const String _keySessionReminder = 'security_session_reminder';
  static const String _keyRememberDevice = 'security_remember_device';

  bool _isLoading = true;
  bool _loginAlerts = true;
  bool _sessionReminder = true;
  bool _rememberDevice = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loginAlerts = prefs.getBool(_keyLoginAlerts) ?? true;
      _sessionReminder = prefs.getBool(_keySessionReminder) ?? true;
      _rememberDevice = prefs.getBool(_keyRememberDevice) ?? true;
      _isLoading = false;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: const CustomAppBar(
        title: 'Keamanan Login',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF012D1D)),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 22),
                  _buildSection(
                    title: 'Proteksi Dasar',
                    description:
                        'Pengaturan ringan untuk membantu kamu tetap sadar dengan aktivitas login akun.',
                    children: [
                      _buildSwitchTile(
                        title: 'Peringatan saat login',
                        subtitle:
                            'Tampilkan pengingat ketika ada login baru atau aktivitas masuk yang penting.',
                        value: _loginAlerts,
                        onChanged: (value) async {
                          setState(() => _loginAlerts = value);
                          await _save(_keyLoginAlerts, value);
                        },
                        icon: Icons.notification_important_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Pengingat sesi aktif',
                        subtitle:
                            'Beri tahu saat sesi akun perlu dicek ulang atau login ulang.',
                        value: _sessionReminder,
                        onChanged: (value) async {
                          setState(() => _sessionReminder = value);
                          await _save(_keySessionReminder, value);
                        },
                        icon: Icons.manage_accounts_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Ingat perangkat ini',
                        subtitle:
                            'Simpan preferensi dasar agar kamu tidak perlu terlalu sering mengatur ulang di perangkat ini.',
                        value: _rememberDevice,
                        onChanged: (value) async {
                          setState(() => _rememberDevice = value);
                          await _save(_keyRememberDevice, value);
                        },
                        icon: Icons.devices_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildSessionCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keamanan yang terasa tenang, bukan menegangkan.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Halaman ini membantu kamu menjaga kebiasaan login tetap aman, sambil menunggu kontrol keamanan yang lebih lengkap di tahap berikutnya.',
            style: TextStyle(
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
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F3),
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
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C19),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF012D1D),
            activeTrackColor: const Color(0xFFBFD8CA),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan sesi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Saat ini sesi aktif terdeteksi di perangkat yang sedang kamu gunakan. Kalau nanti kita sudah punya manajemen sesi penuh, bagian ini bisa menampilkan riwayat perangkat dan aktivitas login terbaru.',
            style: TextStyle(
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
}
