import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'owner_return_evidence_screen.dart';

class OwnerReturnShowQRScreen extends StatelessWidget {
  const OwnerReturnShowQRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFDF9F4),
        centerTitle: true,
        title: const Text(
          'Serah Terima',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFC1C8C2), height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. INSTRUCTION ---
            const Padding(
              padding: EdgeInsets.only(top: 24.0, left: 32.0, right: 32.0),
              child: Text(
                'Tunjukkan kode QR ini ke penyewa\nsebagai tanda serah terima',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF000000),
                  height: 1.4,
                ),
              ),
            ),

            // --- 2. RENTAL ITEM CARD ---
            Container(
              margin: const EdgeInsets.only(top: 20.0, left: 24.0, right: 24.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Image.asset(
                      'assets/images/camera_sony.jpg',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sony Camera a6000',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF414844),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Penyewa: Andini Larasati',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5C635E),
                          ),
                        ),
                        Text(
                          '8 Jan - 10 Jan 2025',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5C635E),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 3. QR CODE DISPLAY AREA ---
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'QR Serah Terima',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF9F4),
                      borderRadius: BorderRadius.circular(24.0),
                      border: Border.all(color: const Color(0xFF1B4332), width: 1.0),
                    ),
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const OwnerReturnEvidenceScreen(),
                            ),
                          );
                        },
                        child: QrImageView(
                          data: 'dummy-return-qr-data',
                          version: QrVersions.auto,
                          size: 220.0,
                          backgroundColor: const Color(0xFFFDF9F4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. WARNING BANNER ---
            Container(
              margin: const EdgeInsets.only(top: 24.0, bottom: 40.0, left: 24.0, right: 24.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFDAD6),
                border: Border.all(color: const Color(0xFFFF0000), width: 1.0),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF0000), size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Pemindaian QR ini adalah bukti sah bahwa barang telah dikembalikan. Setelah di-scan, waktu sewa akan resmi dihentikan. Jangan terima barang sebelum QR ini berhasil dipindai oleh penyewa.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF000000),
                        height: 1.83,
                      ),
                    ),
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
