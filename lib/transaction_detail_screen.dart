import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'scan_qr_renter_screen.dart';
import 'dispute_form_screen.dart';
import 'api_config.dart';
import 'auth_session_service.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/transaction_repository.dart';
import 'handover_show_qr_screen.dart';
import 'return_item_scan_screen.dart';
import 'owner_return_show_qr_screen.dart';
import 'payment_screen.dart';
import 'rental_deadline_screen.dart';
import 'return_evidence_screen.dart';
import 'owner_return_evidence_screen.dart';


class TransactionDetailScreen extends StatefulWidget {
  final String? transactionId;
  const TransactionDetailScreen({super.key, this.transactionId});

  @override
  State<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends State<TransactionDetailScreen> {
  final TransactionRepository _repository = TransactionRepository();
  bool _isLoading = false;
  String? _errorMessage;
  TransactionModel? _transaction;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    _fetchTransactionDetails();
  }

  Future<void> _fetchPaymentStatus() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) return;

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/$tId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final payments = body['data'] as List<dynamic>;
          final hasPaid = payments.any((p) => p['status'] == 'paid');
          if (mounted) {
            setState(() {
              _isPaid = hasPaid;
            });
          }
          return;
        }
      }
    } catch (_) {
      // Silently ignore
    }
  }

  Future<void> _fetchTransactionDetails() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      setState(() {
        _errorMessage = "ID Transaksi tidak valid.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transaction = await _repository.fetchTransactionById(tId);
      
      final statusLower = transaction.status.toLowerCase();
      if (statusLower != 'pending' && statusLower != 'cancelled') {
        await _fetchPaymentStatus();
      } else {
        setState(() {
          _isPaid = false;
        });
      }

      setState(() {
        _transaction = transaction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _approveTransaction() async {
    final tId = widget.transactionId;
    if (tId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/approve'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permintaan sewa disetujui!'), backgroundColor: Color(0xFF1B4332)),
          );
          _fetchTransactionDetails();
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menyetujui permintaan sewa.'), backgroundColor: Colors.red),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan koneksi.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelTransaction() async {
    final tId = widget.transactionId;
    if (tId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/transactions/$tId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi dibatalkan.'), backgroundColor: Color(0xFF1B4332)),
          );
          _fetchTransactionDetails();
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membatalkan transaksi.'), backgroundColor: Colors.red),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan koneksi.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approveAdendum() async {
    final tId = widget.transactionId;
    if (tId == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _repository.approveAdendum(tId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perpanjangan sewa disetujui!'), backgroundColor: Color(0xFF1B4332)),
      );
      _fetchTransactionDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectAdendum() async {
    final tId = widget.transactionId;
    if (tId == null) return;
    
    setState(() => _isLoading = true);
    try {
      await _repository.rejectAdendum(tId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perpanjangan sewa ditolak.'), backgroundColor: Color(0xFF1B4332)),
      );
      _fetchTransactionDetails();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmManualPayment() async {
    final tId = widget.transactionId;
    if (tId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Konfirmasi Pembayaran COD',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF012D1D)),
        ),
        content: Text(
          "Apakah Anda yakin telah menerima pembayaran tunai (COD) sebesar Rp. ${_transaction?.totalPrice != null ? _transaction!.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.') : '0'} dari penyewa?",
          style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF414844)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal', style: TextStyle(color: Colors.red, fontFamily: 'Poppins')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF012D1D),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Ya, Konfirmasi', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/confirm-manual'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionId': tId,
          'method': 'cash',
          'amount': _transaction?.totalPrice ?? 0.0,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pembayaran COD berhasil dikonfirmasi!'),
              backgroundColor: Color(0xFF1B4332),
            ),
          );
          if (mounted) {
            setState(() {
              _isPaid = true;
            });
          }
          _fetchTransactionDetails();
          return;
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengonfirmasi pembayaran.'), backgroundColor: Colors.red),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan koneksi.'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
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
      case 'waiting_rating':
        return 'Menunggu Rating Kedua Pihak';
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
      case 'waiting_rating':
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
      case 'waiting_rating':
        return Icons.star_half_rounded;
      default:
        return Icons.sync;
    }
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '';
    if (dt is! DateTime) return '';
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]}, ${dt.year} • $hourStr:$minStr';
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 'Detail Transaksi';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    if (start.year == end.year) {
      if (start.month == end.month) {
        return '${start.day} - ${end.day} ${months[start.month - 1]} ${start.year}';
      } else {
        return '${start.day} ${months[start.month - 1]} - ${end.day} ${months[end.month - 1]} ${start.year}';
      }
    }
    return '${start.day} ${months[start.month - 1]} ${start.year} - ${end.day} ${months[end.month - 1]} ${end.year}';
  }


  @override
  Widget build(BuildContext context) {
    final status = _transaction?.status ?? 'pending';
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isRenter =
        _transaction?.renterId == currentUserId || widget.transactionId == null;

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

    if (_transaction == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF9F4),
        body: Center(child: Text('Data transaksi kosong.')),
      );
    }

    final detail = _transaction!.details.isNotEmpty
        ? _transaction!.details.first
        : null;
    final itemName = detail?.itemNameSnapshot ?? 'Barang Sewaan';
    final itemPhoto = detail?.itemPhotoUrlSnapshot ?? '';
    final itemPrice = detail?.priceAtBooking ?? 0.0;
    final priceStr =
        "Rp. ${itemPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/jam";

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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF012D1D)),
            tooltip: 'Segarkan',
            onPressed: _fetchTransactionDetails,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFC1C8C2), height: 1.0),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTransactionDetails,
        color: const Color(0xFF012D1D),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
            if (_transaction?.adendumRequest != null && (_transaction!.adendumRequest!.status == 'pending' || (_transaction!.adendumRequest!.status == 'approved' && _transaction!.adendumRequest!.paymentMethod == 'midtrans' && _transaction!.adendumRequest!.paymentStatus == 'pending' && isRenter))) ...[
              _buildAdendumBanner(isRenter),
              const SizedBox(height: 24),
            ],
            if (status.toLowerCase() == 'ongoing') ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8EF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF012D1D), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_outlined, color: Color(0xFF012D1D), size: 28),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Pelacakan Waktu & Tenggat',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF012D1D),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lihat hitung mundur sisa waktu sewa dan status pengembalian.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: Color(0xFF414844),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RentalDeadlineScreen(
                              transactionId: widget.transactionId,
                            ),
                          ),
                        ).then((_) => _fetchTransactionDetails());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF012D1D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: const Text(
                        'Lihat',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],


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
                      color: Colors.grey.shade200,
                      image: itemPhoto.isNotEmpty &&
                              (itemPhoto.startsWith('http') ||
                                  itemPhoto.startsWith('assets/'))
                          ? DecorationImage(
                              image: itemPhoto.startsWith('http')
                                  ? NetworkImage(itemPhoto)
                                  : AssetImage(itemPhoto) as ImageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (itemPhoto.isEmpty ||
                            (!itemPhoto.startsWith('http') &&
                                !itemPhoto.startsWith('assets/')))
                        ? const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Color(0xFF828282),
                              size: 32,
                            ),
                          )
                        : null,
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
                        if (status.toLowerCase() != 'pending' && status.toLowerCase() != 'cancelled') ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isPaid ? const Color(0xFFD0E1D4) : const Color(0xFFFFF2F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isPaid ? Icons.check_circle : Icons.error_outline,
                                  size: 14,
                                  color: _isPaid ? const Color(0xFF012D1D) : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _isPaid ? 'Pembayaran: Lunas' : 'Pembayaran: Belum Bayar',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _isPaid ? const Color(0xFF012D1D) : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rincian Sewa Card
            Builder(
              builder: (context) {
                String durationText = "-";
                if (detail?.startDate != null && detail?.endDate != null) {
                  final diff = detail!.endDate!.difference(detail.startDate!);
                  final hours = diff.inHours;
                  if (hours >= 24) {
                    final days = (hours / 24).ceil();
                    durationText = "$days Hari ($hours Jam)";
                  } else {
                    durationText = "$hours Jam";
                  }
                }

                return Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RINCIAN SEWA',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Penyewa', _transaction?.renterName ?? '-'),
                      _buildSummaryRow('Pemilik', _transaction?.ownerName ?? '-'),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFE8E4DE)),
                      _buildSummaryRow('Tanggal Mulai', _formatDate(detail?.startDate)),
                      _buildSummaryRow('Tanggal Selesai', _formatDate(detail?.endDate)),
                      _buildSummaryRow('Durasi Sewa', durationText),
                      _buildSummaryRow('Jumlah Unit', '${_transaction?.totalItems ?? 1} barang'),
                      const Divider(height: 24, thickness: 1, color: Color(0xFFE8E4DE)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Pembayaran',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF414844),
                            ),
                          ),
                          Text(
                            "Rp. ${_transaction != null ? _transaction!.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.') : '0'}",
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B5804),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }
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
                    time: _formatDate(_transaction?.createdAt),
                    note: 'Transaksi diajukan oleh penyewa.',
                    badgeColor: const Color(0xFFC1ECD4),
                    isLast: false,
                    isCurrent: status.toLowerCase() == 'pending',
                  ),
                  _buildTimelineStep(
                    title: 'Approved',
                    time: _formatDate(_transaction?.updatedAt),
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
                      time: _formatDate(_transaction?.updatedAt),
                      note:
                          'Sengketa diajukan. Sistem menangguhkan dana sewa sementara.',
                      badgeColor: const Color(0xFF7B5804),
                      isLast: true,
                      isCurrent: true,
                    ),
                  ] else ...[
                    _buildTimelineStep(
                      title: 'Sewa Berlangsung',
                      time:
                          status.toLowerCase() == 'ongoing' ||
                              status.toLowerCase() == 'completed'
                          ? _formatDate(_transaction?.checkinAt)
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
                          ? _formatDate(_transaction?.checkoutAt)
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
    ),
      bottomNavigationBar: _buildBottomNavigationBar(status, isRenter, itemName, itemPhoto),
    );
  }

  Widget? _buildBottomNavigationBar(String status, bool isRenter, String itemName, String itemPhoto) {
    status = status.toLowerCase();
    
    final detail = _transaction?.details.isNotEmpty == true ? _transaction!.details.first : null;
    final startDate = detail?.startDate;
    final endDate = detail?.endDate;
    
    if (status == 'pending') {
      if (!isRenter) {
        // Owner pending view
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _cancelTransaction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFBA1A1A),
                      side: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    child: const Text(
                      'Tolak',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _approveTransaction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF012D1D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Setujui',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Renter pending view
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: OutlinedButton(
              onPressed: _cancelTransaction,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFBA1A1A),
                side: const BorderSide(color: Color(0xFFBA1A1A), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: const Text(
                'Batalkan Permintaan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }
    }
    
    if (status == 'approved') {
      if (isRenter) {
        if (!_isPaid) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PaymentScreen(
                        transactionId: widget.transactionId ?? '',
                        totalPrice: _transaction?.totalPrice ?? 0.0,
                        itemName: itemName,
                        itemPhoto: itemPhoto,
                        ownerName: _transaction?.ownerName ?? 'Owner',
                      ),
                    ),
                  ).then((value) {
                    if (value == true) {
                      _fetchTransactionDetails();
                    }
                  });
                },
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text(
                  'Bayar Sekarang',
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
          );
        }
        return SafeArea(
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
                        'owner': 'Pemilik: ${_transaction?.ownerName ?? 'Owner'}',
                        'date': _formatDateRange(startDate, endDate),
                        'image': itemPhoto,
                      },
                      transactionId: widget.transactionId,
                    ),
                  ),
                ).then((_) => _fetchTransactionDetails());
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
                backgroundColor: const Color(0xFF012D1D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                elevation: 0,
              ),
            ),
          ),
        );
      } else {
        // Owner approved: show QR code and COD confirmation if unpaid
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isPaid) ...[
                  ElevatedButton.icon(
                    onPressed: _confirmManualPayment,
                    icon: const Icon(Icons.monetization_on, color: Colors.white),
                    label: const Text(
                      'Konfirmasi Terima Uang (COD)',
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
                  const SizedBox(height: 12),
                ],
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HandoverShowQRScreen(
                          itemData: {
                            'title': itemName,
                            'owner': 'Penyewa: ${_transaction?.renterName ?? 'Renter'}',
                            'date': _formatDateRange(startDate, endDate),
                            'image': itemPhoto,
                          },
                          transactionId: widget.transactionId,
                        ),
                      ),
                    ).then((_) => _fetchTransactionDetails());
                  },
                  icon: const Icon(Icons.qr_code, color: Colors.white),
                  label: const Text(
                    'Tampilkan QR Serah Terima',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF012D1D),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    if (status == 'ongoing') {
      if (isRenter) {
        // Renter ongoing: Return Item (opens OwnerReturnShowQRScreen)
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OwnerReturnShowQRScreen(
                      itemData: {
                        'title': itemName,
                        'owner': 'Pemilik: ${_transaction?.ownerName ?? 'Owner'}',
                        'date': _formatDateRange(startDate, endDate),
                        'image': itemPhoto,
                      },
                      transactionId: widget.transactionId,
                    ),
                  ),
                ).then((_) => _fetchTransactionDetails());
              },
              icon: const Icon(Icons.assignment_return_outlined, color: Colors.white),
              label: const Text(
                'Kembalikan Barang',
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
        );
      } else {
        // Owner ongoing: Scan QR return (opens ReturnItemScanScreen)
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReturnItemScanScreen(
                      transactionId: widget.transactionId,
                      itemName: itemName,
                    ),
                  ),
                ).then((_) => _fetchTransactionDetails());
              },
              icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
              label: const Text(
                'Scan QR Pengembalian',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
                elevation: 0,
              ),
            ),
          ),
        );
      }
    }
    
    if (status == 'waiting_rating') {
      final hasRated = _transaction?.hasUserRated ?? false;
      if (!hasRated) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: ElevatedButton.icon(
              onPressed: () {
                if (isRenter) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReturnEvidenceScreen(
                        transactionId: widget.transactionId,
                        itemName: itemName,
                        isForced: true,
                      ),
                    ),
                  ).then((_) => _fetchTransactionDetails());
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OwnerReturnEvidenceScreen(
                        transactionId: widget.transactionId,
                        itemName: itemName,
                        isForced: true,
                      ),
                    ),
                  ).then((_) => _fetchTransactionDetails());
                }
              },
              icon: const Icon(Icons.star_rounded, color: Colors.white),
              label: const Text(
                'Berikan Rating & Ulasan',
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
        );
      } else {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFC1C8C2),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: const Center(
                child: Text(
                  'Menunggu partner memberikan rating',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    
    return null;
  }

  Widget _buildDisputeActionButtons(
    String status,
    bool isRenter,
    String itemName,
  ) {
    if (!isRenter) return const SizedBox.shrink();

    if (status.toLowerCase() == 'approved') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: () =>
                _navigateToDispute(context, 'handover_rejection', itemName),
            icon: const Icon(Icons.gpp_bad_outlined, color: Colors.red),
            label: const Text(
              'Barang Rusak saat COD (Tolak Terima)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
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
            onPressed: () =>
                _navigateToDispute(context, 'ongoing_damage', itemName),
            icon: const Icon(
              Icons.report_problem_outlined,
              color: Colors.orange,
            ),
            label: const Text(
              'Laporkan Kerusakan Barang (Sewa Berjalan)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
              ),
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

  void _navigateToDispute(
    BuildContext context,
    String category,
    String itemName,
  ) async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID Transaksi tidak valid')),
        );
      }
      return;
    }
    
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF012D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdendumBanner(bool isRenter) {
    final adendum = _transaction!.adendumRequest!;
    final newDateStr = _formatDate(adendum.newEndDate);
    final costStr = "Rp. ${adendum.additionalCost.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";
    final paymentMethodStr = adendum.paymentMethod == 'cash' ? 'Tunai (COD)' : 'Cashless (Midtrans)';

    if (adendum.status == 'approved' && adendum.paymentMethod == 'midtrans' && adendum.paymentStatus == 'pending' && isRenter) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7B5804)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.payment_outlined, color: Color(0xFF7B5804)),
                SizedBox(width: 8),
                Text(
                  'Pembayaran Perpanjangan Sewa',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B5804),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Perpanjangan sewa hingga $newDateStr telah disetujui. Silakan lakukan pembayaran sebesar $costStr.',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: Color(0xFF414844),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : () async {
                  setState(() => _isLoading = true);
                  try {
                    final redirectUrl = await _repository.initiateAdendumPayment(widget.transactionId!);
                    if (redirectUrl.isNotEmpty) {
                      final Uri url = Uri.parse(redirectUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                        // Show confirmation dialog here similar to PaymentScreen
                        if (mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: const Color(0xFFFFF8EF),
                              title: const Text('Menunggu Pembayaran', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                              content: const Text('Silakan selesaikan pembayaran perpanjangan Anda di browser yang terbuka. Setelah selesai, muat ulang halaman ini.', style: TextStyle(fontFamily: 'Poppins')),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _fetchTransactionDetails();
                                  },
                                  child: const Text('Tutup', style: TextStyle(fontFamily: 'Poppins')),
                                )
                              ],
                            ),
                          );
                        }
                      } else {
                        throw Exception('Tidak dapat membuka link pembayaran.');
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF012D1D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Bayar Sekarang',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (isRenter) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8EF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF7B5804)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF7B5804)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Menunggu persetujuan perpanjangan sewa dari pemilik hingga $newDateStr.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Color(0xFF7B5804),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF7B5804), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.more_time_rounded, color: Color(0xFF7B5804), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Permintaan Perpanjangan Sewa',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B5804),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Penyewa mengajukan perpanjangan durasi sewa dengan rincian berikut:',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF414844)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Selesai Baru', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF717973))),
                    Text(newDateStr, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Biaya Tambahan', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF717973))),
                    Text(costStr, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF7B5804))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Metode Bayar', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF717973))),
                    Text(paymentMethodStr, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _rejectAdendum,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Tolak',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _approveAdendum,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF012D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Terima',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
                  border: isCurrent
                      ? Border.all(color: const Color(0xFF012D1D), width: 3)
                      : null,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: const Color(0xFFC1C8C2)),
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
