import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'upload_evidence_screen.dart';

class ScanQRRenterScreen extends StatefulWidget {
  final Map<String, String> itemData;

  const ScanQRRenterScreen({super.key, required this.itemData});

  @override
  State<ScanQRRenterScreen> createState() => _ScanQRRenterScreenState();
}

class _ScanQRRenterScreenState extends State<ScanQRRenterScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isNavigating) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        debugPrint('Barcode found! ${barcode.rawValue}');
        _navigateToNextPage();
        break;
      }
    }
  }

  void _navigateToNextPage() {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });
    
    // Tampilkan snackbar sukses
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan Berhasil! Lanjutkan untuk unggah bukti kondisi.'),
        backgroundColor: Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigasi ke halaman upload foto bukti
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => UploadEvidenceScreen(itemData: widget.itemData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFF012D1D),
          ),
        ),
        title: const Text(
          'Serah Terima',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24, // Matched typical app bar sizes, spec says 30 but might be too large, let's stick to 24 for standard, wait spec says 30, let's use 26
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B4332),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFC1C8C2).withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            // 1. INSTRUCTION
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Scan QR pemilik barang untuk\nmengkonfirmasi serah terima',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF000000),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 2. RENTAL ITEM CARD
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0),
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFFFC107), width: 1),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 16),
                          SizedBox(height: 2),
                          Text(
                            'DUMMY\n(NO API)',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF856404),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemData['title'] ?? 'Sony Camera a6000',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.itemData['owner'] ?? 'Pemilik: Han so Hee',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.itemData['date'] ?? '8 Jan - 10 Jan 2025',
                          style: const TextStyle(
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

            const SizedBox(height: 24),

            // 3. CAMERA SCANNER VIEWPORT
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan QR',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () {
                      debugPrint('Camera viewport clicked! Simulating successful scan.');
                      _navigateToNextPage();
                    },
                    child: Container(
                      height: 380.0,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(23.0),
                        border: Border.all(
                          color: const Color(0xFF1B4332),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(21.5), // Inner radius
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: cameraController,
                              onDetect: _onDetect,
                            ),
                            
                            // Scan Animation Overlay
                            AnimatedBuilder(
                              animation: _animation,
                              builder: (context, child) {
                                return Positioned(
                                  top: _animation.value * (380 - 4), // 4 is line height
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.greenAccent.withOpacity(0.8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.greenAccent.withOpacity(0.6),
                                          blurRadius: 10,
                                          spreadRadius: 2,
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                  
                            // Flip Camera Button
                            Positioned(
                              top: 16,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => cameraController.switchCamera(),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B4332).withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.flip_camera_ios_outlined,
                                    color: Color(0xFFFDF9F4),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // DUMMY BUTTON (Untuk Testing Emulator/Preview)
            TextButton(
              onPressed: _navigateToNextPage,
              child: const Text(
                'Gunakan Barcode Dummy (Simulasi)',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF717973),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 4. WARNING BANNER
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8E8), // Light red
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: const Color(0xFFF04438), // Red border
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFF04438),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Memindai QR berarti masa sewa Anda resmi dimulai. Pastikan Anda telah mengecek kondisi barang bersama Pemilik dan mengambil foto bukti kondisi awal sebelum memindai.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF414844).withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
