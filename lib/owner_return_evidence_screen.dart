import 'package:flutter/material.dart';

class OwnerReturnEvidenceScreen extends StatefulWidget {
  const OwnerReturnEvidenceScreen({super.key});

  @override
  State<OwnerReturnEvidenceScreen> createState() => _OwnerReturnEvidenceScreenState();
}

class _OwnerReturnEvidenceScreenState extends State<OwnerReturnEvidenceScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();

  void _submit() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap berikan rating untuk penyewa.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Verifikasi dan rating berhasil disimpan!'),
        backgroundColor: Color(0xFF1B4332),
      ),
    );
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- 1. INSTRUCTION TEXT ---
            const Padding(
              padding: EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Text(
                'Foto bukti kondisi barang setelah peminjaman yang dikirimkan oleh penyewa',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF000000),
                ),
              ),
            ),

            // --- ITEM CARD --- (Based on Screenshot)
            Container(
              margin: const EdgeInsets.only(top: 16.0, left: 20.0, right: 20.0),
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
                      'assets/images/camera_sony.jpg', // Dummy placeholder
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sony Camera a6000',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414844),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Penyewa: Andini Larasati',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF414844),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '8 Jan - 10 Jan 2025',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF414844),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. EVIDENCE GALLERY (READ-ONLY) ---
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
                  const SizedBox(height: 12),
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
                      children: List.generate(5, (index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(11.0),
                          child: Container(
                            width: 70,
                            height: 70,
                            color: const Color(0xFFC1ECD4), // Placeholder background
                            child: Image.asset(
                              'assets/images/camera_sony.jpg', // Simulasi foto pengembalian
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            // --- 3. RATING RENTER SECTION ---
            Padding(
              padding: const EdgeInsets.only(top: 32.0, left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Rating Penyewa',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16.0),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _rating = index + 1;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Icon(
                                  Icons.star_rounded,
                                  size: 40,
                                  color: index < _rating ? const Color(0xFFF8BD00) : const Color(0xFFEFEFEF),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEFEF),
                            borderRadius: BorderRadius.circular(11.0),
                          ),
                          child: TextField(
                            controller: _reviewController,
                            minLines: 5,
                            maxLines: 8,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Color(0xFF000000),
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Berikan ulasan anda disini...',
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: Color(0xFF717973),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. ACTION BUTTON ---
            GestureDetector(
              onTap: _submit,
              child: Container(
                margin: const EdgeInsets.only(top: 40.0, bottom: 40.0, left: 20.0, right: 20.0),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D),
                  borderRadius: BorderRadius.circular(999.0),
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
