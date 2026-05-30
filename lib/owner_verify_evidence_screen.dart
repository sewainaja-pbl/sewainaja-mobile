import 'package:flutter/material.dart';

class OwnerVerifyEvidenceScreen extends StatelessWidget {
  final Map<String, String> itemData;

  const OwnerVerifyEvidenceScreen({super.key, required this.itemData});

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
          child: Container(
            color: const Color(0xFFC1C8C2),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. INSTRUCTION TEXT ---
            const Padding(
              padding: EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Text(
                'Foto bukti kondisi barang sebelum peminjaman yang dikirimkan oleh penyewa',
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
              margin: const EdgeInsets.only(top: 24.0, left: 20.0, right: 20.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.asset(
                      itemData['image'] ?? 'assets/images/placeholder.png',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemData['title'] ?? 'Sony Camera a6000',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemData['owner'] ?? 'Penyewa: Andini Larasati',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5C635E),
                          ),
                        ),
                        Text(
                          itemData['date'] ?? '8 Jan - 10 Jan 2025',
                          style: const TextStyle(
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

            // --- 3. PHOTO EVIDENCE GALLERY (READ-ONLY) ---
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bukti Foto',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(26.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      children: List.generate(
                        6, // Contoh 6 foto yang diunggah penyewa
                        (index) => ClipRRect(
                          borderRadius: BorderRadius.circular(11.0),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: const Color(0xFFC1ECD4), // Hijau mint pudar placeholder
                            child: Icon(
                              Icons.image,
                              color: const Color(0xFF012D1D).withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. ACTION BUTTON ---
            GestureDetector(
              onTap: () {
                // TODO: Logika konfirmasi selesai
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Konfirmasi serah terima berhasil!')),
                );
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Container(
                margin: const EdgeInsets.only(top: 40.0, bottom: 40.0, left: 20.0, right: 20.0),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D),
                  borderRadius: BorderRadius.circular(999.0), // Pill shape
                ),
                child: const Center(
                  child: Text(
                    'Konfirmasi',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFDF9F4),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
