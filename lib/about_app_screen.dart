import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const String _appVersion = '1.0.0+1';

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
          'Tentang SewaInAja',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOverviewCard(),
            const SizedBox(height: 22),
            _buildInfoSection(),
            const SizedBox(height: 22),
            _buildRoadmapSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0E4A31),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF012D1D).withValues(alpha: 0.14),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sewa barang terasa lebih dekat, ringkas, dan gampang dipahami.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'SewaInAja dirancang untuk membantu pengguna menemukan barang sewa di sekitar, mengatur profil dengan lebih praktis, dan menjaga alur transaksi tetap rapi dari awal sampai selesai.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: Color(0xFFE6F1EB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Informasi Aplikasi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          SizedBox(height: 16),
          _InfoRow(label: 'Versi', value: _appVersion),
          SizedBox(height: 12),
          _InfoRow(label: 'Status', value: 'Sedang terus dikembangkan'),
          SizedBox(height: 12),
          _InfoRow(label: 'Fokus saat ini', value: 'Sinkronisasi profil dan pengaturan dasar'),
          SizedBox(height: 12),
          _InfoRow(
            label: 'Catatan',
            value: 'Beberapa menu masih akan dilengkapi bertahap supaya fondasi pengalaman utamanya tetap stabil dan nyaman dipakai.',
            multiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRoadmapSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tahap berikutnya',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          SizedBox(height: 14),
          _RoadmapTile(
            title: 'Preferensi notifikasi',
            subtitle: 'Kontrol yang lebih rapi untuk update chat, sewa, dan pengingat.',
          ),
          SizedBox(height: 12),
          _RoadmapTile(
            title: 'Privasi dan keamanan akun',
            subtitle: 'Pengaturan sesi aktif, visibilitas profil, dan proteksi login yang lebih lengkap.',
          ),
          SizedBox(height: 12),
          _RoadmapTile(
            title: 'Bantuan lanjutan',
            subtitle: 'Kontak bantuan, laporan masalah, dan panduan yang lebih lengkap.',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool multiline;

  const _InfoRow({
    required this.label,
    required this.value,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
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
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoadmapTile extends StatelessWidget {
  final String title;
  final String subtitle;

  const _RoadmapTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: Color(0xFF0E4A31),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
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
                  color: Color(0xFF1C1C19),
                ),
              ),
              const SizedBox(height: 4),
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
            ],
          ),
        ),
      ],
    );
  }
}
