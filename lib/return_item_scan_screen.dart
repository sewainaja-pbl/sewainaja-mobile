import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_session_service.dart';
import 'owner_return_evidence_screen.dart';

class ReturnItemScanScreen extends StatefulWidget {
  final String? transactionId;
  final String? itemName;
  const ReturnItemScanScreen({super.key, this.transactionId, this.itemName});

  @override
  State<ReturnItemScanScreen> createState() => _ReturnItemScanScreenState();
}

class _ReturnItemScanScreenState extends State<ReturnItemScanScreen> with SingleTickerProviderStateMixin {
  final MobileScannerController cameraController = MobileScannerController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isNavigating = false;

  Map<String, dynamic>? _transactionData;
  List<dynamic> _details = [];

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

    _fetchTransactionDetails();
  }

  Future<void> _fetchTransactionDetails() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) return;

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _transactionData = body['data'] as Map<String, dynamic>;
            _details = _transactionData!['details'] as List? ?? [];
          });
        }
      }
    } catch (_) {
    }
  }

  String _formatDateRange() {
    if (_details.isEmpty) return '8 Jan - 10 Jan 2025';
    final detail = _details[0];
    final start = detail['startDate'];
    final end = detail['endDate'];
    if (start == null || end == null) return '8 Jan - 10 Jan 2025';
    
    final sDt = _parseTimestamp(start);
    final eDt = _parseTimestamp(end);
    if (sDt == null || eDt == null) return '8 Jan - 10 Jan 2025';

    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${sDt.day} ${months[sDt.month - 1]} - ${eDt.day} ${months[eDt.month - 1]} ${eDt.year}';
  }

  DateTime? _parseTimestamp(dynamic ts) {
    if (ts == null) return null;
    if (ts is Map) {
      final sec = ts['_seconds'] ?? ts['seconds'];
      if (sec is int) {
        return DateTime.fromMillisecondsSinceEpoch(sec * 1000).toLocal();
      }
    } else if (ts is String) {
      return DateTime.tryParse(ts)?.toLocal();
    }
    return null;
  }

  ImageProvider _getImageProvider() {
    if (_details.isNotEmpty) {
      final url = _details[0]['itemPhotoUrlSnapshot']?.toString();
      if (url != null && url.isNotEmpty) {
        if (url.startsWith('http')) {
          return NetworkImage(url);
        } else if (url.startsWith('assets/')) {
          return AssetImage(url);
        }
      }
    }
    return const AssetImage('assets/images/Iklan.jpg');
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
    if (barcodes.isNotEmpty) {
      final String? token = barcodes.first.rawValue;
      if (token != null) {
        _processScanSuccess(token);
      }
    }
  }

  Future<void> _processScanSuccess(String token) async {
    if (_isNavigating) return;
    setState(() {
      _isNavigating = true;
    });
    
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B4332)),
      ),
    );

    try {
      final tId = widget.transactionId;
      if (tId == null || tId.isEmpty) {
        // Simulasi jika tidak ada transactionId
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Simulasi Berhasil! Lanjut verifikasi pengembalian.'),
            backgroundColor: Color(0xFF1B4332),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => OwnerReturnEvidenceScreen(
              transactionId: 'dummy_trans_123',
              itemName: widget.itemName ?? 'Sony Camera a6000',
            ),
          ),
        );
        return;
      }

      final idToken = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/checkout'),
        headers: headers,
        body: jsonEncode({
          'token': token,
        }),
      );

      if (mounted) Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Berhasil scan QR pengembalian!'),
                backgroundColor: Color(0xFF1B4332),
              ),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerReturnEvidenceScreen(
                  transactionId: widget.transactionId,
                  itemName: widget.itemName,
                ),
              ),
            );
          }
        } else {
          throw Exception(body['message'] ?? 'Gagal memproses pengembalian barang.');
        }
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Gagal memproses pengembalian barang.');
      }
    } catch (e) {
      if (mounted) {
        // Pastikan loading dialog ditutup
        Navigator.pop(context);
        setState(() {
          _isNavigating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: const Color(0xFFF04438),
          ),
        );
      }
    }
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
            // --- 1. INSTRUCTION ---
            const Padding(
              padding: EdgeInsets.only(top: 24.0, left: 32.0, right: 32.0),
              child: Text(
                'Scan QR pemilik barang untuk mengkonfirmasi serah terima',
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
                children: [
                  Builder(
                    builder: (context) {
                      final imageUrl = _details.isNotEmpty ? _details[0]['itemPhotoUrlSnapshot']?.toString() : null;
                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                      return Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade200,
                          image: hasImage
                              ? DecorationImage(
                                  image: imageUrl.startsWith('http')
                                      ? NetworkImage(imageUrl)
                                      : AssetImage(imageUrl) as ImageProvider,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: !hasImage
                            ? const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF828282),
                                  size: 24,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _details.isNotEmpty
                                            ? _details[0]['itemNameSnapshot']?.toString() ?? widget.itemName ?? 'Barang Sewaan'
                                            : widget.itemName ?? 'Sony Camera a6000',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF414844),
                                        ),
                                      ),
                                    ),
                                    if (widget.transactionId == null || widget.transactionId == 'dummy_trans_123')
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECEB),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: const Color(0xFFF04438), width: 0.5),
                                        ),
                                        child: const Text(
                                          'DUMMY',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFF04438),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                        const SizedBox(height: 4),
                        Text(
                          _transactionData != null
                              ? 'Penyewa: ${_transactionData!['renterName'] ?? 'Penyewa'}'
                              : 'Penyewa: Andini Larasati',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5C635E),
                          ),
                        ),
                        Text(
                          _formatDateRange(),
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

            // --- 3. CAMERA SCANNER VIEWPORT ---
            GestureDetector(
              onTap: () => _processScanSuccess('dummy-return-qr-token'), // Dummy simulation here!
              child: Container(
                margin: const EdgeInsets.only(top: 32.0, left: 24.0, right: 24.0),
                height: 350.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF000000),
                  borderRadius: BorderRadius.circular(23.0),
                  border: Border.all(color: const Color(0xFF1B4332), width: 1.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22.0),
                  child: Stack(
                    children: [
                      // Actual Camera Feed
                      MobileScanner(
                        controller: cameraController,
                        onDetect: _onDetect,
                      ),
                      
                      // Animated scanning line
                      AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return Positioned(
                            top: _animation.value * 350.0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 3.0,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC1ECD4).withOpacity(0.8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFC1ECD4).withOpacity(0.5),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Scan QR Text (Center)
                      const Center(
                        child: Text(
                          'Scan QR',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFFFFFF),
                          ),
                        ),
                      ),
                      
                      // Flip Camera Button (Bottom Right)
                      Positioned(
                        bottom: 16.0,
                        right: 16.0,
                        child: IconButton(
                          icon: const Icon(Icons.change_circle_outlined),
                          color: const Color(0xFFFDF9F4),
                          iconSize: 32.0,
                          onPressed: () {
                            cameraController.switchCamera();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // DUMMY BUTTON (Untuk Testing Emulator/Preview)
            TextButton(
              onPressed: () => _processScanSuccess('dummy-return-qr-token'),
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

            // --- 4. RETURN WARNING BANNER (CRITICAL) ---
            Container(
              margin: const EdgeInsets.only(top: 32.0, bottom: 40.0, left: 24.0, right: 24.0),
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
                      'Scan QR ini berfungsi untuk menghentikan waktu sewa dan menonaktifkan pelacakan GPS. Jika terlewat, transaksi akan terus berjalan dan tagihan penyewa dapat membengkak.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF000000),
                        height: 1.5,
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
