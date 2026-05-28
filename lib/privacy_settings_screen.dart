import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  static const String _keyPublicProfile = 'privacy_public_profile';
  static const String _keyShowLocation = 'privacy_show_location';
  static const String _keyShowFavorites = 'privacy_show_favorites';

  bool _isLoading = true;
  bool _publicProfile = true;
  bool _showLocation = true;
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _publicProfile = prefs.getBool(_keyPublicProfile) ?? true;
      _showLocation = prefs.getBool(_keyShowLocation) ?? true;
      _showFavorites = prefs.getBool(_keyShowFavorites) ?? false;
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
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Privasi Akun',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF012D1D)),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 22),
                  _buildSection(
                    title: 'Visibilitas Profil',
                    description:
                        'Atur seberapa banyak informasi akunmu yang terlihat di aplikasi.',
                    children: [
                      _buildSwitchTile(
                        title: 'Tampilkan profil ke pengguna lain',
                        subtitle:
                            'Biarkan nama dan identitas dasar akunmu tetap terlihat saat berinteraksi.',
                        value: _publicProfile,
                        onChanged: (value) async {
                          setState(() => _publicProfile = value);
                          await _save(_keyPublicProfile, value);
                        },
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Tampilkan area lokasi utama',
                        subtitle:
                            'Tampilkan area umum lokasi untuk membantu konteks pencarian dan transaksi.',
                        value: _showLocation,
                        onChanged: (value) async {
                          setState(() => _showLocation = value);
                          await _save(_keyShowLocation, value);
                        },
                        icon: Icons.location_on_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Tampilkan daftar favorit',
                        subtitle:
                            'Izinkan daftar barang favoritmu terlihat sebagai referensi ringan.',
                        value: _showFavorites,
                        onChanged: (value) async {
                          setState(() => _showFavorites = value);
                          await _save(_keyShowFavorites, value);
                        },
                        icon: Icons.favorite_border_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildFootnote(),
                ],
              ),
            ),
    );
  }

  Widget _buildIntroCard() {
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
            'Atur privasi secukupnya, tanpa bikin pengalaman jadi ribet.',
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
            'Pengaturan ini membantu kamu menentukan informasi mana yang tetap terbuka dan mana yang lebih baik dijaga seperlunya.',
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

  Widget _buildFootnote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Text(
        'Untuk tahap sekarang, preferensi privasi ini masih disimpan di perangkat dulu. Nantinya, pengaturan yang benar-benar sensitif bisa kita sinkronkan langsung ke akun.',
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
