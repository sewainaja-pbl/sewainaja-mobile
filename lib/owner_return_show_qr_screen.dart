import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_session_service.dart';
import 'owner_return_evidence_screen.dart';
import 'return_evidence_screen.dart';
import 'widgets/custom_app_bar.dart';

class OwnerReturnShowQRScreen extends StatefulWidget {
  final Map<String, String>? itemData;
  final String? transactionId;

  const OwnerReturnShowQRScreen({super.key, this.itemData, this.transactionId});

  @override
  State<OwnerReturnShowQRScreen> createState() => _OwnerReturnShowQRScreenState();
}

class _OwnerReturnShowQRScreenState extends State<OwnerReturnShowQRScreen> {
  bool _isRefreshing = false;
  bool _isNavigated = false;

  Future<void> _refreshQR() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Simulasi Refresh: Token QR diperbarui')),
      );
      return;
    }

    setState(() {
      _isRefreshing = true;
    });

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/regenerate-qr'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kode QR Berhasil Diperbarui!'),
                backgroundColor: Color(0xFF1B4332),
              ),
            );
          }
        } else {
          throw Exception(body['error']?['message'] ?? body['message'] ?? 'Gagal me-regenerate QR');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memperbarui QR: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _navigateToEvidence() {
    if (_isNavigated) return;
    _isNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReturnEvidenceScreen(
            transactionId: widget.transactionId,
            itemName: widget.itemData?['title'] ?? 'Sony Camera a6000',
            isForced: true,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactionId == null) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Serah Terima'),
        body: Center(child: Text('ID Transaksi tidak ditemukan.')),
      );
    }

    Widget qrCodeWidget;
    qrCodeWidget = StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .doc(widget.transactionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text('Gagal memuat status QR secara real-time');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator(color: Color(0xFF012D1D));
          }

          final data = snapshot.data?.data() as Map<String, dynamic>?;
          if (data == null) {
            return const Text('Transaksi tidak ditemukan.');
          }

          final status = data['status']?.toString() ?? 'pending';
          final token = data['qrCheckoutTokenHash']?.toString() ?? '';
          final expiredAt = data['qrCheckoutExpiredAt'];

          // Auto navigate if status changes to waiting_rating or completed
          if (status.toLowerCase() == 'waiting_rating' || status.toLowerCase() == 'completed') {
            _navigateToEvidence();
          }

          if (token.isEmpty) {
            return const Text('Token QR tidak tersedia.');
          }

          // Check if token expired
          bool isExpired = false;
          if (expiredAt != null) {
            DateTime? expTime;
            if (expiredAt is Timestamp) {
              expTime = expiredAt.toDate();
            } else if (expiredAt is String) {
              expTime = DateTime.tryParse(expiredAt);
            }
            if (expTime != null && DateTime.now().isAfter(expTime)) {
              isExpired = true;
            }
          }

          // Check Adendum COD
          Widget? codAlert;
          if (data['adendumRequest'] != null) {
            final adendum = data['adendumRequest'];
            if (adendum['status'] == 'approved' && adendum['paymentMethod'] == 'cash' && adendum['paymentStatus'] == 'pending') {
              final amountStr = "Rp. ${(adendum['additionalCost'] ?? 0).toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
              codAlert = Container(
                margin: const EdgeInsets.only(bottom: 24),
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
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (codAlert != null) codAlert,
              Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: isExpired ? 0.2 : 1.0,
                    child: QrImageView(
                      data: token,
                      version: QrVersions.auto,
                      size: 220.0,
                      backgroundColor: const Color(0xFFFDF9F4),
                    ),
                  ),
                  if (isExpired)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'QR KADALUWARSA\nHarap klik tombol Refresh',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      );

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: const CustomAppBar(
        title: 'Serah Terima',
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // --- 1. INSTRUCTION ---
            const Padding(
              padding: EdgeInsets.only(top: 24.0, left: 32.0, right: 32.0),
              child: Text(
                'Tunjukkan kode QR ini ke penyewa\nsebagai tanda serah terima pengembalian',
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
                    color: Colors.black.withValues(alpha: 0.05),
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
                    child: widget.itemData?['image'] != null && widget.itemData!['image']!.isNotEmpty
                        ? (widget.itemData!['image']!.startsWith('http')
                            ? Image.network(
                                widget.itemData!['image']!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              )
                            : Image.asset(
                                widget.itemData!['image']!,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 64,
                                  height: 64,
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ))
                        : Container(
                            width: 64,
                            height: 64,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemData?['title'] ?? 'Sony Camera a6000',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.itemData?['owner'] ?? 'Penyewa: Andini Larasati',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5C635E),
                          ),
                        ),
                        Text(
                          widget.itemData?['date'] ?? '8 Jan - 10 Jan 2025',
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
                      child: qrCodeWidget,
                    ),
                  ),
                  if (widget.transactionId != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isRefreshing ? null : _refreshQR,
                        icon: _isRefreshing 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B4332)),
                              )
                            : const Icon(Icons.refresh, color: Color(0xFF1B4332)),
                        label: const Text(
                          'Refresh QR Code',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B4332),
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: Color(0xFF1B4332), width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
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
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF0000), size: 24),
                  SizedBox(width: 12),
                  Expanded(
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
