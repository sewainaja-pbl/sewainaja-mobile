import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_session_service.dart';
import 'payment_webview_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String transactionId;
  final double totalPrice;
  final String itemName;
  final String itemPhoto;
  final String ownerName;

  const PaymentScreen({
    super.key,
    required this.transactionId,
    required this.totalPrice,
    required this.itemName,
    required this.itemPhoto,
    required this.ownerName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _selectedMethod = 'midtrans'; // 'midtrans' or 'cash'
  bool _hasInitiatedMidtrans = false;

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  Future<void> _initiateMidtransPayment() async {
    setState(() => _isLoading = true);

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/initiate'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionId': widget.transactionId,
        }),
      );

      final body = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && body['success'] == true) {
        final redirectUrl = body['data']['redirect_url']?.toString();
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          setState(() {
            _hasInitiatedMidtrans = true;
          });
          if (mounted) {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentWebViewScreen(url: redirectUrl),
              ),
            );
            if (mounted) {
              if (result == true) {
                _checkPaymentStatus();
              } else {
                _showErrorSnackBar('Pembayaran dibatalkan atau belum diselesaikan.');
              }
            }
          }
        } else {
          _showErrorSnackBar('Gagal mendapatkan link pembayaran Midtrans.');
        }
      } else {
        _showErrorSnackBar(body['error']?['message'] ?? 'Gagal membuat transaksi.');
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Terjadi kesalahan koneksi.');
    }
  }

  Future<void> _confirmCashPayment() async {
    setState(() => _isLoading = true);

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/payments/initiate-cash'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'transactionId': widget.transactionId,
        }),
      );

      final body = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && body['success'] == true) {
        _showCODPendingDialog('Permintaan Pembayaran Tunai (COD) berhasil dikirim! Silakan lakukan pembayaran tunai ke pemilik barang saat serah terima.');
      } else {
        _showErrorSnackBar(body['error']?['message'] ?? 'Gagal memproses pembayaran tunai.');
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Terjadi kesalahan koneksi.');
    }
  }

  Future<void> _checkPaymentStatus() async {
    setState(() => _isLoading = true);

    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/payments/${widget.transactionId}'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);
      setState(() => _isLoading = false);

      if (response.statusCode == 200 && body['success'] == true) {
        final payments = body['data'] as List<dynamic>;
        final isPaid = payments.any((p) => p['status'] == 'paid');

        if (isPaid) {
          if (mounted) {
            _showSuccessDialog('Pembayaran terverifikasi! Status transaksi diperbarui.');
          }
        } else {
          _showErrorSnackBar('Pembayaran belum terdeteksi. Harap selesaikan transaksi Anda.');
        }
      } else {
        final errorMsg = body['error']?['message'] ?? body['message'] ?? 'Gagal mengecek status pembayaran.';
        _showErrorSnackBar(errorMsg);
      }
    } catch (_) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Terjadi kesalahan koneksi.');
    }
  }

  void _showCODPendingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF7B5804), size: 60),
            const SizedBox(height: 16),
            const Text(
              'Metode COD Dipilih',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF012D1D)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF414844), fontSize: 13),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Pop back to detail screen with success indicator
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Tutup', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF2F6743), size: 60),
            const SizedBox(height: 16),
            const Text(
              'Pembayaran Sukses',
              style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF012D1D)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF414844), fontSize: 13),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context, true); // Pop back to detail screen with success indicator
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Tutup', style: TextStyle(color: Colors.white, fontFamily: 'Poppins')),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.red,
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF012D1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pembayaran',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: const Color(0xFFC1C8C2), height: 1.0),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF012D1D)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. ITEM SUMMARY CARD
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
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
                            image: widget.itemPhoto.isNotEmpty && widget.itemPhoto.startsWith('http')
                                ? DecorationImage(
                                    image: NetworkImage(widget.itemPhoto),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (widget.itemPhoto.isEmpty || !widget.itemPhoto.startsWith('http'))
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
                              Text(
                                widget.itemName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF012D1D),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Pemilik: ${widget.ownerName}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  color: Color(0xFF717973),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rp. ${_formatCurrency(widget.totalPrice)}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF7B5804),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 2. PAYMENT METHODS SECTION
                  const Text(
                    'Pilih Metode Pembayaran',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Method 1: Cashless / Midtrans
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'midtrans'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedMethod == 'midtrans' ? const Color(0xFF7B5804) : Colors.transparent,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF3CD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF7B5804)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Pembayaran Cashless (Online)',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF012D1D),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Bayar otomatis via Midtrans (E-Wallet/VA). Uang ditahan aman oleh sistem.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF717973),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _selectedMethod == 'midtrans' ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: _selectedMethod == 'midtrans' ? const Color(0xFF7B5804) : const Color(0xFFC1C8C2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Method 2: Cash / COD
                  GestureDetector(
                    onTap: () => setState(() => _selectedMethod = 'cash'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _selectedMethod == 'cash' ? const Color(0xFF012D1D) : Colors.transparent,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFD0E1D4),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.payments_outlined, color: Color(0xFF012D1D)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Bayar Tunai (COD)',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF012D1D),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Serahkan pembayaran tunai langsung ke pemilik saat serah terima barang.',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: Color(0xFF717973),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            _selectedMethod == 'cash' ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: _selectedMethod == 'cash' ? const Color(0xFF012D1D) : const Color(0xFFC1C8C2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 3. CONFIRM ACTION BUTTON
                  ElevatedButton(
                    onPressed: _selectedMethod == 'midtrans' ? _initiateMidtransPayment : _confirmCashPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF012D1D),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 0,
                    ),
                    child: Text(
                      _selectedMethod == 'midtrans' ? 'Bayar Sekarang' : 'Konfirmasi Bayar Tunai (COD)',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  if (_hasInitiatedMidtrans && _selectedMethod == 'midtrans') ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _checkPaymentStatus,
                      icon: const Icon(Icons.refresh, color: Color(0xFF012D1D)),
                      label: const Text(
                        'Cek Status Verifikasi Pembayaran',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF012D1D), width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // 4. DEVELOPER MODE SIMULATION TOOLS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report_outlined, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'DEVELOPER FLOW BYPASS',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Simulasikan pembayaran langsung di server (tanpa Midtrans/tunai asli) untuk pengujian cepat.',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF5C3C3C)),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _confirmCashPayment,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.red, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text(
                            'Simulasikan Sukses Instan (Bypass)',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
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
