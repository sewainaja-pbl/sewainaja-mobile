import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_session_service.dart';
import 'widgets/custom_app_bar.dart';

class OwnerVerifyEvidenceScreen extends StatefulWidget {
  final Map<String, String> itemData;
  final String? transactionId;

  const OwnerVerifyEvidenceScreen({
    super.key,
    required this.itemData,
    this.transactionId,
  });

  @override
  State<OwnerVerifyEvidenceScreen> createState() => _OwnerVerifyEvidenceScreenState();
}

class _OwnerVerifyEvidenceScreenState extends State<OwnerVerifyEvidenceScreen> {
  List<dynamic> _beforeEvidences = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEvidences();
  }

  Future<void> _fetchEvidences() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/evidences'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final allEvidences = body['data'] as List<dynamic>;
          setState(() {
            _beforeEvidences = allEvidences
                .where((e) => e['type'] == 'before')
                .toList();
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage = 'Gagal mengambil bukti foto.';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: CustomAppBar(
        title: 'Serah Terima',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF012D1D)),
            onPressed: _fetchEvidences,
          ),
        ],
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
                    child: widget.itemData['image'] != null && widget.itemData['image']!.isNotEmpty
                        ? (widget.itemData['image']!.startsWith('http')
                            ? Image.network(
                                widget.itemData['image']!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                widget.itemData['image']!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ))
                        : Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(width: 12),
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
                    child: _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(color: Color(0xFF012D1D)),
                            ),
                          )
                        : _errorMessage != null
                            ? Center(child: Text(_errorMessage!))
                            : _beforeEvidences.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Text('Tidak ada foto bukti.'),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 12.0,
                                    runSpacing: 12.0,
                                    children: List.generate(
                                      _beforeEvidences.length,
                                      (index) {
                                        final url = _beforeEvidences[index]['mediaUrl']?.toString() ?? '';
                                        return GestureDetector(
                                          onTap: () {
                                            if (url.isNotEmpty) {
                                              showDialog(
                                                context: context,
                                                builder: (_) => Dialog(
                                                  child: Image.network(url),
                                                ),
                                              );
                                            }
                                          },
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(11.0),
                                            child: Container(
                                              width: 70,
                                              height: 70,
                                              color: const Color(0xFFC1ECD4),
                                              child: url.startsWith('http')
                                                  ? Image.network(
                                                      url,
                                                      width: 70,
                                                      height: 70,
                                                      fit: BoxFit.cover,
                                                    )
                                                  : Icon(
                                                      Icons.image,
                                                      color: const Color(0xFF012D1D).withOpacity(0.3),
                                                    ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                  ),
                ],
              ),
            ),

            // --- 4. ACTION BUTTON ---
            GestureDetector(
              onTap: () {
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
                    'Konfirmasi Selesai',
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
