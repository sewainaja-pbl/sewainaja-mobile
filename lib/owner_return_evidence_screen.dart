import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_session_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_navigation_screen.dart';
import 'widgets/custom_app_bar.dart';

class OwnerReturnEvidenceScreen extends StatefulWidget {
  final String? transactionId;
  final String? itemName;
  final bool isForced;
  final bool isRoot;
  const OwnerReturnEvidenceScreen({
    super.key,
    this.transactionId,
    this.itemName,
    this.isForced = true,
    this.isRoot = false,
  });

  @override
  State<OwnerReturnEvidenceScreen> createState() => _OwnerReturnEvidenceScreenState();
}

class _OwnerReturnEvidenceScreenState extends State<OwnerReturnEvidenceScreen> {
  int _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  bool _isLoadingEvidences = false;
  Map<String, dynamic>? _transactionData;
  List<dynamic> _details = [];
  List<dynamic> _afterEvidences = [];
  String? _evidencesError;
  bool _canPop = false;

  @override
  void initState() {
    super.initState();
    _savePendingRatingState();
    _fetchDetailsAndEvidences();
  }

  Future<void> _savePendingRatingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_rating_id', widget.transactionId ?? '');
      await prefs.setString('pending_rating_item_name', widget.itemName ?? '');
      await prefs.setString('pending_rating_role', 'owner');
    } catch (e) {
      debugPrint('Error saving pending rating state: $e');
    }
  }



  Future<void> _fetchDetailsAndEvidences() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) return;

    setState(() {
      _isLoadingEvidences = true;
      _evidencesError = null;
    });

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // 1. Fetch transaction details
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

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      // 2. Fetch evidences
      final evidenceResp = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/evidences'),
        headers: headers,
      );

      if (evidenceResp.statusCode == 200) {
        final body = jsonDecode(evidenceResp.body);
        if (body['success'] == true && body['data'] != null) {
          final allEvidences = body['data'] as List<dynamic>;
          setState(() {
            _afterEvidences = allEvidences.where((e) => e['type'] == 'after').toList();
          });
        } else {
          setState(() {
            _evidencesError = body['message'] ?? 'Gagal memuat bukti.';
          });
        }
      } else {
        setState(() {
          _evidencesError = 'Server error: ${evidenceResp.statusCode}';
        });
      }
    } catch (_) {
      setState(() {
        _evidencesError = 'Kesalahan koneksi.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEvidences = false;
        });
      }
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

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap berikan rating untuk penyewa.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final tId = widget.transactionId;
    final detail = _details.isNotEmpty ? _details.first : null;
    final itemImage = (detail != null && detail['itemPhotoUrlSnapshot'] != null)
        ? detail['itemPhotoUrlSnapshot'].toString()
        : '';
    if (tId == null || tId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Transaksi tidak valid.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF012D1D)),
      ),
    );

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ratings'),
        headers: headers,
        body: jsonEncode({
          'transactionId': tId,
          'ratedAs': 'renter',
          'score': _rating,
          'comment': _reviewController.text.trim(),
        }),
      );

      if (mounted) Navigator.pop(context); // Tutup loading dialog

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          if (mounted) {
            setState(() {
              _canPop = true;
            });
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return _OwnerReturnSuccessModal(
                  itemName: _details.isNotEmpty
                      ? _details[0]['itemNameSnapshot']?.toString() ?? widget.itemName ?? 'Barang'
                      : widget.itemName ?? 'Sony Camera a6000',
                  dateRange: _formatDateRange(),
                  itemImage: itemImage,
                  isRoot: widget.isRoot,
                );
              },
            );
          }
        } else {
          throw Exception(body['error']?['message'] ?? body['message'] ?? 'Gagal mengirim ulasan.');
        }
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['error']?['message'] ?? body['message'] ?? 'Gagal mengirim ulasan.');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Tutup loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<bool> _showExitConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Keluar dari Halaman?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: Color(0xFF012D1D),
          ),
        ),
        content: const Text(
          'Anda belum menyelesaikan pengisian bukti serah terima/pengembalian dan rating. Jika Anda keluar sekarang, data bukti sewa Anda tidak akan tersimpan secara lengkap. Yakin ingin keluar?',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: Color(0xFF414844),
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Color(0xFF1B4332),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Keluar',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.isForced ? false : _canPop,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        if (widget.isForced) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Anda wajib memberikan rating untuk menyelesaikan transaksi.'),
              backgroundColor: Color(0xFFF04438),
            ),
          );
          return;
        }
        final shouldPop = await _showExitConfirmationDialog();
        if (shouldPop) {
          setState(() {
            _canPop = true;
          });
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF9F4),
        appBar: CustomAppBar(
          title: 'Serah Terima',
          showBackButton: !widget.isForced,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF012D1D)),
              onPressed: _fetchDetailsAndEvidences,
            ),
          ],
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

            // --- ITEM CARD ---
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
                  Builder(
                    builder: (context) {
                      final imageUrl = _details.isNotEmpty ? _details[0]['itemPhotoUrlSnapshot']?.toString() : null;
                      final hasImage = imageUrl != null && imageUrl.isNotEmpty;
                      return Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
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
                  const SizedBox(width: 12),
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
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF414844),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _transactionData != null
                              ? 'Penyewa: ${_transactionData!['renterName'] ?? 'Penyewa'}'
                              : 'Penyewa: Andini Larasati',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateRange(),
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
                    child: _isLoadingEvidences
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(color: Color(0xFF012D1D)),
                            ),
                          )
                        : _evidencesError != null
                            ? Center(child: Text(_evidencesError!))
                            : _afterEvidences.isEmpty
                                ? const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Text(
                                        'Tidak ada foto bukti pengembalian.',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          color: Color(0xFF717973),
                                        ),
                                      ),
                                    ),
                                  )
                                : Wrap(
                                    spacing: 12.0,
                                    runSpacing: 12.0,
                                    children: List.generate(_afterEvidences.length, (index) {
                                      final url = _afterEvidences[index]['mediaUrl']?.toString() ?? '';
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
                                            color: const Color(0xFFFFF3CD),
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
              onTap: _isSubmitting ? null : _submit,
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
    ),
   );
  }
}

class _OwnerReturnSuccessModal extends StatelessWidget {
  final String itemName;
  final String dateRange;
  final String itemImage;
  final bool isRoot;
  const _OwnerReturnSuccessModal({
    required this.itemName,
    required this.dateRange,
    required this.itemImage,
    this.isRoot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30.0),
      ),
      backgroundColor: const Color(0xFFFDF9F4),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close Button
            Align(
              alignment: Alignment.topRight,
              child: GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('pending_rating_id');
                  await prefs.remove('pending_rating_item_name');
                  await prefs.remove('pending_rating_role');
                  if (context.mounted) {
                    if (isRoot) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                      );
                    } else {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  }
                },
                child: const Icon(Icons.close, color: Color(0xFF414844), size: 24),
              ),
            ),
            
            // Checkmark Icon
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFC1ECD4),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFF012D1D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Color(0xFFC1ECD4), size: 20),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            const Text(
              'Pengembalian Selesai!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF012D1D),
              ),
            ),
            const SizedBox(height: 12),
            
            // Subtitle
            const Text(
              'Proses serah terima pengembalian barang telah berhasil. Dana sewa akan segera diteruskan ke saldo Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF414844),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            // Item Details Card
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF2E7), // Light beige for inner card
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade200,
                        image: itemImage.isNotEmpty && itemImage.startsWith('http')
                            ? DecorationImage(
                                image: NetworkImage(itemImage),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (itemImage.isEmpty || !itemImage.startsWith('http'))
                          ? const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Color(0xFF828282),
                                size: 32,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RINCIAN SEWA',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF8A6136),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF414844)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dateRange,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF414844),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Action Button
            GestureDetector(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('pending_rating_id');
                await prefs.remove('pending_rating_item_name');
                await prefs.remove('pending_rating_role');
                if (context.mounted) {
                  if (isRoot) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                    );
                  } else {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  }
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(999.0),
                  border: Border.all(color: const Color(0xFF1B4332), width: 1.0),
                ),
                child: const Center(
                  child: Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1B4332),
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
