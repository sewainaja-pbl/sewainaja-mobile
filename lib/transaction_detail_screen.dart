import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';
import 'auth_session_service.dart';
import 'scan_qr_renter_screen.dart';
import 'dispute_form_screen.dart';

class TransactionDetailScreen extends StatefulWidget {
  final String? transactionId;
  const TransactionDetailScreen({super.key, this.transactionId});

  @override
  State<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _transactionData;
  List<dynamic> _details = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
  }

  Future<void> _fetchTransactionDetails() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      // Load fallback dummy data
      setState(() {
        _transactionData = _getFallbackTransactionData();
        _details = _getFallbackDetails();
        _isLoading = false;
        _errorMessage = null;
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
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          setState(() {
            _transactionData = body['data'] as Map<String, dynamic>;
            _details = _transactionData!['details'] as List? ?? [];
            _isLoading = false;
          });
          return;
        }
      }
      setState(() {
        _errorMessage = 'Gagal memuat detail transaksi.';
        _isLoading = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Terjadi kesalahan koneksi.';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _getFallbackTransactionData() {
    return {
      'id': 'dummy_trans_123',
      'renterId': 'dummy_renter_uid',
      'ownerId': 'dummy_owner_uid',
      'renterName': 'Aminah',
      'ownerName': 'Han so Hee',
      'status': 'approved',
      'totalPrice': 1080000,
      'createdAt': {'_seconds': 1744535520, '_nanoseconds': 0},
      'approvedAt': {'_seconds': 1744555520, '_nanoseconds': 0},
    };
  }

  List<dynamic> _getFallbackDetails() {
    return [
      {
        'itemId': 'dummy_item_1',
        'itemNameSnapshot': 'Sony ɑ6000 Body Only',
        'itemPhotoUrlSnapshot': '',
        'priceAtBooking': 15000.0,
        'subtotal': 1080000,
      }
    ];
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'approved':
        return 'Menunggu Serah Terima';
      case 'ongoing':
        return 'Sewa Berlangsung';
      case 'completed':
        return 'Sewa Selesai';
      case 'cancelled':
        return 'Transaksi Dibatalkan';
      case 'disputed':
        return 'Dalam Sengketa';
      default:
        return status.toUpperCase();
    }
  }

  Color _getStatusBgColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return const Color(0xFF7B5804); // Gold/amber
      case 'approved':
        return const Color(0xFF2F6743); // Hijau
      case 'ongoing':
        return const Color(0xFF012D1D); // Hijau gelap
      case 'completed':
        return const Color(0xFF10B981); // Hijau terang
      case 'cancelled':
        return const Color(0xFFBA1A1A); // Merah
      case 'disputed':
        return const Color(0xFF7B5804); // Amber
      default:
        return const Color(0xFF012D1D);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.sync;
      case 'ongoing':
        return Icons.play_arrow;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      case 'disputed':
        return Icons.gpp_maybe;
      default:
        return Icons.sync;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime? dt;
    if (timestamp is Map) {
      final sec = timestamp['_seconds'] ?? timestamp['seconds'];
      if (sec is int) {
        dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000).toLocal();
      }
    } else if (timestamp is String) {
      dt = DateTime.tryParse(timestamp)?.toLocal();
    }
    if (dt == null) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year} • $hourStr:$minStr';
  }

  @override
  Widget build(BuildContext context) {
    final status = _transactionData?['status']?.toString() ?? 'pending';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isRenter = _transactionData?['renterId'] == currentUserId || widget.transactionId == null;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF9F4),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF012D1D)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFDF9F4),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFDF9F4),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _fetchTransactionDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF012D1D),
                  ),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_transactionData == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF9F4),
        body: Center(child: Text('Data transaksi kosong.')),
      );
    }

    final itemName = _details.isNotEmpty ? _details[0]['itemNameSnapshot']?.toString() ?? 'Barang Sewaan' : 'Barang Sewaan';
    final itemPhoto = _details.isNotEmpty ? _details[0]['itemPhotoUrlSnapshot']?.toString() ?? '' : '';
    final itemPrice = _details.isNotEmpty ? (_details[0]['priceAtBooking'] as num).toDouble() : 15000.0;
    final priceStr = "Rp. ${itemPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/jam";

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF012D1D),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFFFDF9F4),
                size: 20,
              ),
            ),
          ),
        ),
        title: const Text(
          'Detail',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // STATUS CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getStatusBgColor(status),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF012D1D),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _formatStatus(status),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ITEM DETAILS CARD
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: itemPhoto.isNotEmpty && (itemPhoto.startsWith('http') || itemPhoto.startsWith('assets/'))
                            ? (itemPhoto.startsWith('http')
                                ? NetworkImage(itemPhoto)
                                : AssetImage(itemPhoto) as ImageProvider)
                            : const AssetImage('assets/images/Iklan.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRODUK DISEWA',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF7B5804),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          priceStr,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF7B5804),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // TIMELINE SECTION
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F3EE),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.history, color: Color(0xFF012D1D)),
                      SizedBox(width: 8),
                      Text(
                        'Timeline Transaksi',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildTimelineStep(
                    title: 'Requested',
                    time: _formatDate(_transactionData?['createdAt']),
                    note: 'Transaksi diajukan oleh penyewa.',
                    badgeColor: const Color(0xFFC1ECD4),
                    isLast: false,
                    isCurrent: status.toLowerCase() == 'pending',
                  ),
                  _buildTimelineStep(
                    title: 'Approved',
                    time: _formatDate(_transactionData?['approvedAt']),
                    note: 'Transaksi disetujui oleh pemilik barang.',
                    badgeColor: status.toLowerCase() == 'pending'
                        ? const Color(0xFFC1C8C2)
                        : const Color(0xFFC1ECD4),
                    isLast: false,
                    isCurrent: status.toLowerCase() == 'approved',
                  ),
                  if (status.toLowerCase() == 'disputed') ...[
                    _buildTimelineStep(
                      title: 'Dalam Sengketa (Disputed)',
                      time: _formatDate(_transactionData?['updatedAt']),
                      note: 'Sengketa diajukan. Sistem menangguhkan dana sewa sementara.',
                      badgeColor: const Color(0xFF7B5804),
                      isLast: true,
                      isCurrent: true,
                    ),
                  ] else ...[
                    _buildTimelineStep(
                      title: 'Sewa Berlangsung',
                      time: status.toLowerCase() == 'ongoing' || status.toLowerCase() == 'completed'
                          ? _formatDate(_transactionData?['checkinAt'])
                          : '',
                      note: '',
                      badgeColor: status.toLowerCase() == 'ongoing'
                          ? const Color(0xFF012D1D)
                          : (status.toLowerCase() == 'completed'
                              ? const Color(0xFFC1ECD4)
                              : const Color(0xFFC1C8C2)),
                      isLast: false,
                      isCurrent: status.toLowerCase() == 'ongoing',
                    ),
                    _buildTimelineStep(
                      title: 'Sewa Selesai',
                      time: status.toLowerCase() == 'completed'
                          ? _formatDate(_transactionData?['checkoutAt'])
                          : '',
                      note: '',
                      badgeColor: status.toLowerCase() == 'completed'
                          ? const Color(0xFF10B981)
                          : const Color(0xFFC1C8C2),
                      isLast: true,
                      isCurrent: status.toLowerCase() == 'completed',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // KONDISI TOMBOL AKSI
            if (status.toLowerCase() == 'disputed') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4DB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF5D3A1)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.gpp_maybe, color: Color(0xFF9A6700)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Transaksi ini ditangguhkan karena dalam Sengketa (Disputed). Menunggu proses peninjauan bukti-bukti dan keputusan mediasi dari Admin.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          color: Color(0xFF6B4B02),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildDisputeActionButtons(status, isRenter, itemName),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: status.toLowerCase() == 'approved' && isRenter
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScanQRRenterScreen(
                          itemData: {
                            'title': itemName,
                            'owner': 'Pemilik: ${_transactionData?['ownerName'] ?? 'Owner'}',
                            'date': 'Detail Transaksi',
                            'image': itemPhoto,
                          },
                          transactionId: widget.transactionId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.handshake, color: Colors.white),
                  label: const Text(
                    'Mulai Serah Terima',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5804),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildDisputeActionButtons(String status, bool isRenter, String itemName) {
    if (!isRenter) return const SizedBox.shrink();

    if (status.toLowerCase() == 'approved') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _navigateToDispute(context, 'handover_rejection', itemName),
            icon: const Icon(Icons.gpp_bad_outlined, color: Colors.red),
            label: const Text(
              'Barang Rusak saat COD (Tolak Terima)',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.red, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      );
    } else if (status.toLowerCase() == 'ongoing') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () => _navigateToDispute(context, 'ongoing_damage', itemName),
            icon: const Icon(Icons.report_problem_outlined, color: Colors.orange),
            label: const Text(
              'Laporkan Kerusakan Barang (Sewa Berjalan)',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Colors.orange, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  void _navigateToDispute(BuildContext context, String category, String itemName) async {
    final tId = widget.transactionId ?? 'dummy_trans_123';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DisputeFormScreen(
          transactionId: tId,
          category: category,
          itemName: itemName,
        ),
      ),
    );

    if (result == true) {
      _fetchTransactionDetails();
    }
  }

  Widget _buildTimelineStep({
    required String title,
    required String time,
    required String note,
    required Color badgeColor,
    required bool isLast,
    bool isCurrent = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: badgeColor,
                  shape: BoxShape.circle,
                  border: isCurrent ? Border.all(color: const Color(0xFF012D1D), width: 3) : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFC1C8C2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                      color: const Color(0xFF012D1D),
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      time,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF717973),
                      ),
                    ),
                  ],
                  if (note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        note,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Color(0xFF414844),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
