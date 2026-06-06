import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_session_service.dart';
import 'owner_verify_evidence_screen.dart';

class HandoverShowQRScreen extends StatefulWidget {
  final Map<String, String> itemData;
  final String? transactionId;

  const HandoverShowQRScreen({super.key, required this.itemData, this.transactionId});

  @override
  State<HandoverShowQRScreen> createState() => _HandoverShowQRScreenState();
}

class _HandoverShowQRScreenState extends State<HandoverShowQRScreen> {
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
          throw Exception(body['message'] ?? 'Gagal me-regenerate QR');
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

  void _navigateToVerify() {
    if (_isNavigated) return;
    _isNavigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => OwnerVerifyEvidenceScreen(itemData: widget.itemData),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final initialQRData = widget.transactionId != null 
        ? "INITIAL_TOKEN_${widget.transactionId}" 
        : "HANDOVER_QR_DATA_${widget.itemData['title']}";

    Widget qrCodeWidget;
    if (widget.transactionId != null) {
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
          final token = data['qrCheckinTokenHash']?.toString() ?? '';
          final expiredAt = data['qrCheckinExpiredAt'];

          // Auto navigate if status changes to ongoing
          if (status.toLowerCase() == 'ongoing') {
            _navigateToVerify();
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

          return Stack(
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
          );
        },
      );
    } else {
      // Fallback/mock mode
      qrCodeWidget = GestureDetector(
        onTap: () {
          // Dummy simulation to go to OwnerVerifyEvidenceScreen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OwnerVerifyEvidenceScreen(itemData: widget.itemData),
            ),
          );
        },
        child: QrImageView(
          data: initialQRData,
          version: QrVersions.auto,
          size: 220.0,
          backgroundColor: const Color(0xFFFDF9F4),
        ),
      );
    }

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
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.itemData['title'] ?? 'Sony Camera a6000',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.itemData['owner'] ?? 'Penyewa: Andini Larasati',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF5C635E),
                          ),
                        ),
                        Text(
                          widget.itemData['date'] ?? '8 Jan - 10 Jan 2025',
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
                      'Pemindaian QR ini adalah bukti sah bahwa barang telah diserahkan. Setelah di-scan, waktu sewa akan resmi berjalan. Jangan serahkan barang sebelum QR ini berhasil dipindai.',
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
