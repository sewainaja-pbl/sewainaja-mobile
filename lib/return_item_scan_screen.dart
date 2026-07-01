import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'dart:convert';
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

    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) return;

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final detailsResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId'),
        headers: headers,
      );

      if (detailsResp.statusCode == 200) {
        final body = jsonDecode(detailsResp.body);
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
        setState(() {
          _isNavigating = true;
        });
        _performCheckout(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _performCheckout(String token) async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Transaksi tidak valid.'),
          backgroundColor: Color(0xFFF04438),
        ),
      );
      setState(() {
        _isNavigating = false;
      });
      return;
    }

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF1B4332)),
      ),
    );

    try {
      final idToken = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        'Connection': 'close',
        if (idToken != null) 'Authorization': 'Bearer $idToken',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/checkout'),
        headers: headers,
        body: jsonEncode({'token': token}),
      );

      final body = jsonDecode(response.body);
      if ((response.statusCode == 200 && body['success'] == true) || response.statusCode == 409) {
        if (mounted) Navigator.pop(context); // Tutup loading dialog
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Check-out berhasil! Barang telah dikembalikan.'),
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
      } else {
        throw Exception(body['message'] ?? 'Gagal melakukan check-out.');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Tutup loading dialog
      if (mounted) {
        setState(() {
          _isNavigating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal check-out: ${e.toString()}'),
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
                'Scan QR penyewa barang untuk mengkonfirmasi serah terima',
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
                        Text(
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
                        const SizedBox(height: 4),
                        Text(
                          _transactionData != null
                              ? 'Pemilik: ${_transactionData!['ownerName'] ?? 'Pemilik'}'
                              : 'Pemilik: Han so Hee',
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

            if (_transactionData != null && _transactionData!['adendumRequest'] != null && _transactionData!['adendumRequest']['status'] == 'approved' && _transactionData!['adendumRequest']['paymentMethod'] == 'cash' && _transactionData!['adendumRequest']['paymentStatus'] == 'pending')
              Builder(
                builder: (context) {
                  final adendum = _transactionData!['adendumRequest'];
                  final amountStr = "Rp. ${(adendum['additionalCost'] ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
                  return Container(
                    margin: const EdgeInsets.only(top: 24, left: 24, right: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8EF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF7B5804), width: 1.5),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.payments_outlined, color: Color(0xFF7B5804)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tagihan Tunai (COD) Perpanjangan',
                                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF7B5804)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Penyewa harus membayar uang tunai sebesar $amountStr untuk perpanjangan sewa saat pengembalian barang.',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF414844)),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFFFFF8EF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: const Text('Konfirmasi Pembayaran COD', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                                  content: Text('Apakah Anda yakin telah menerima pembayaran tunai sebesar $amountStr dari penyewa?', style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF414844))),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Batal', style: TextStyle(color: Colors.red, fontFamily: 'Poppins')),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF012D1D)),
                                      child: const Text('Ya, Konfirmasi', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                try {
                                  final token = await const AuthSessionService().getValidIdToken(forceRefresh: true);
                                  if (token == null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Sesi Anda telah berakhir. Harap login kembali.'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                    return;
                                  }
                                  final response = await http.post(
                                    Uri.parse('${ApiConfig.baseUrl}/payments/confirm-manual'),
                                    headers: {
                                      'Content-Type': 'application/json',
                                      'Authorization': 'Bearer $token',
                                    },
                                    body: jsonEncode({
                                      'transactionId': widget.transactionId,
                                      'method': 'cash',
                                      'amount': adendum['additionalCost'] ?? 0,
                                    }),
                                  );
                                  if (response.statusCode == 200) {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pembayaran COD berhasil dikonfirmasi!'), backgroundColor: Color(0xFF1B4332)));
                                    _fetchDetails(); // Refresh to hide the button
                                  } else {
                                    final body = jsonDecode(response.body);
                                    throw Exception(body['error']?['message'] ?? body['message'] ?? 'Gagal mengonfirmasi pembayaran.');
                                  }
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan koneksi.'), backgroundColor: Colors.red));
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF012D1D),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Konfirmasi Uang Diterima', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

            // --- 3. CAMERA SCANNER VIEWPORT ---
            Container(
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
