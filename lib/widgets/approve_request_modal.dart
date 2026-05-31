import 'package:flutter/material.dart';

class ApproveRequestModal extends StatelessWidget {
  const ApproveRequestModal({super.key});

  /// Cara penggunaan: 
  /// ApproveRequestModal.show(context);
  static void show(BuildContext context) {
    showDialog(
      context: context,
      // Mengatur background di belakang modal (parent_bg) menjadi hijau tua sesuai spesifikasi
      barrierColor: const Color(0xFF1B4332).withValues(alpha: 0.9),
      builder: (context) => const ApproveRequestModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(40),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // INDIKATOR VISUAL SUKSES (BADGE ELEMEN)
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFC1ECD4),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check, 
                color: Color(0xFF012D1D),
                size: 32,
              ),
            ),
            const SizedBox(height: 24),
            
            // KONTEN TEKS MODAL
            const Text(
              'Permintaan Disetujui!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF012D1D),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Kini Anda bisa mulai berkomunikasi dengan penyewa untuk mengatur serah terima barang.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF414844),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            
            // TOMBOL AKSI UTAMA & NAVIGASI
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Aksi untuk chat penyewa
                },
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 20),
                label: const Text(
                  'Chat Penyewa',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7B5804),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Aksi untuk melihat detail transaksi
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF1EDE8),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Lihat Detail Transaksi',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            InkWell(
              onTap: () {
                // Aksi untuk kembali ke beranda
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF414844),
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Color(0xFF414844),
                    size: 16,
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
