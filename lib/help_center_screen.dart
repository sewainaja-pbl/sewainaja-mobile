import 'package:flutter/material.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const List<_FaqItem> _faqItems = [
    _FaqItem(
      question: 'Bagaimana cara mulai menyewa barang?',
      answer:
          'Cari barang yang kamu butuhkan, buka detailnya, lalu kirim permintaan sewa sesuai tanggal yang kamu pilih. Setelah pemilik menyetujui, kamu bisa lanjut ke proses serah terima.',
    ),
    _FaqItem(
      question: 'Kenapa alamat utama perlu diatur?',
      answer:
          'Alamat utama membantu aplikasi menyesuaikan area pencarian dan menampilkan rekomendasi barang yang lebih dekat dengan lokasimu.',
    ),
    _FaqItem(
      question: 'Apakah profil bisa diubah dari aplikasi?',
      answer:
          'Saat ini kamu sudah bisa mengubah nama, nomor telepon, foto profil, dan lokasi utama langsung dari aplikasi. Pengaturan lainnya akan dilengkapi bertahap.',
    ),
    _FaqItem(
      question: 'Apa yang harus dilakukan jika login atau sinkronisasi gagal?',
      answer:
          'Coba periksa koneksi internet, tutup lalu buka ulang aplikasi, kemudian login kembali jika sesi sudah berakhir. Kalau masalahnya masih muncul, kamu bisa cek info versi aplikasi di halaman Tentang sebelum melapor.',
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
          'Pusat Bantuan',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(),
            const SizedBox(height: 22),
            _buildFaqSection(),
            const SizedBox(height: 22),
            _buildSupportCard(),
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
            'Bantuan cepat untuk pertanyaan yang paling sering muncul.',
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
            'Halaman ini dirancang sebagai titik bantu pertama, supaya pengguna punya pegangan saat login, mengatur profil, dan menjalankan alur sewa.',
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

  Widget _buildFaqSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FAQ',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jawaban singkat yang bisa bantu kamu lebih cepat paham cara kerja aplikasinya.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
          const SizedBox(height: 16),
          ..._faqItems.map((item) => _FaqTile(item: item)),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
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
          Row(
            children: [
              Icon(
                Icons.support_agent_rounded,
                color: Color(0xFF0E4A31),
                size: 24,
              ),
              SizedBox(width: 10),
              Text(
                'Butuh bantuan lebih lanjut?',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF012D1D),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Untuk sekarang, halaman ini jadi pusat bantuan awal yang paling cepat diakses. Ke depannya, kita bisa sambungkan ke CS, form laporan, atau kontak resmi lainnya.',
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

class _FaqTile extends StatelessWidget {
  final _FaqItem item;

  const _FaqTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          iconColor: const Color(0xFF012D1D),
          collapsedIconColor: const Color(0xFF717973),
          title: Text(
            item.question,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C1C19),
            ),
          ),
          children: [
            Text(
              item.answer,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: Color(0xFF717973),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}
