import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'widgets/subtle_fade_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WalletScreen extends StatefulWidget {
  final double currentBalance;
  const WalletScreen({super.key, this.currentBalance = 0.0});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  double _balance = 0.0;
  double _escrowBalance = 0.0;
  bool _isLoading = true;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _balance = widget.currentBalance;
    _fetchWalletData();
  }

  Future<void> _fetchWalletData() async {
    setState(() => _isLoading = true);
    
    // 1. Sync from local SharedPreferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _balance = prefs.getDouble('user_wallet_balance') ?? widget.currentBalance;
      });
    } catch (_) {}

    // 2. Fetch fresh profile and pending escrow balance from Firestore/API
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        // Fetch current user document for real-time balance
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
            .get();
            
        if (userDoc.exists && mounted) {
          final data = userDoc.data();
          setState(() {
            _balance = (data?['walletBalance'] as num?)?.toDouble() ?? 0.0;
          });
          
          // Save back to local cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setDouble('user_wallet_balance', _balance);
        }

        // Fetch pending escrow payments ('completed_held' status)
        final escrowPaymentsSnap = await FirebaseFirestore.instance
            .collection('payments')
            .where('status', isEqualTo: 'paid')
            .where('escrowStatus', isEqualTo: 'completed_held')
            .get();
        
        // Count how much is pending for transactions belonging to this user
        double pendingSum = 0.0;
        final myTransactionsSnap = await FirebaseFirestore.instance
            .collection('transactions')
            .where('ownerId', isEqualTo: currentUserId)
            .get();
            
        final myTxIds = myTransactionsSnap.docs.map((d) => d.id).toSet();
        
        for (var pDoc in escrowPaymentsSnap.docs) {
          final pData = pDoc.data();
          if (myTxIds.contains(pData['transactionId'])) {
            pendingSum += (pData['amount'] as num?)?.toDouble() ?? 0.0;
          }
        }

        if (mounted) {
          setState(() {
            _escrowBalance = pendingSum;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading wallet details: $e");
    }

    // Load dummy transaction logs for demo
    _loadDummyHistory();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _loadDummyHistory() {
    _history = [
      {
        'title': 'Pendapatan Sewa DSLR Canon',
        'type': 'earning',
        'amount': 180000.0,
        'date': 'Hari ini, 14:20 WIB',
        'status': 'Selesai',
      },
      {
        'title': 'Pencairan Saldo Bank BCA',
        'type': 'withdrawal',
        'amount': 200000.0,
        'date': '5 Jun 2026, 09:00 WIB',
        'status': 'Sukses',
      },
      {
        'title': 'Pendapatan Sewa Sony Camera',
        'type': 'earning',
        'amount': 120000.0,
        'date': '3 Jun 2026, 17:15 WIB',
        'status': 'Selesai',
      },
      {
        'title': 'Pendapatan Sewa Tenda Camping',
        'type': 'earning',
        'amount': 75000.0,
        'date': '28 Mei 2026, 11:30 WIB',
        'status': 'Selesai',
      },
    ];
  }

  String _formatRupiah(double amount) {
    return 'Rp. ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  void _showWithdrawBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _WithdrawBottomSheet(
        maxBalance: _balance,
        onWithdrawSuccess: (amount) {
          setState(() {
            _balance -= amount;
          });
          // Update SharedPreferences
          SharedPreferences.getInstance().then((prefs) {
            prefs.setDouble('user_wallet_balance', _balance);
          });
          // Refresh data after a delay
          Future.delayed(const Duration(seconds: 2), _fetchWalletData);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF), // Cream background
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF012D1D), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Dompet Saya',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF012D1D),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF012D1D)),
            onPressed: _fetchWalletData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF8BD00)),
              ),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1. MAIN CARD WALLET ---
                  FadeInDown(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF012D1D), // Deep Green
                            Color(0xFF0C5237), // Forest Green
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF012D1D).withValues(alpha: 0.25),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SALDO AKTIF',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE8F0EB),
                                  letterSpacing: 1,
                                ),
                              ),
                              Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Color(0xFFF8BD00),
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatRupiah(_balance),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Withdraw CTA Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _balance > 0 ? _showWithdrawBottomSheet : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF8BD00), // Gold Accent
                                foregroundColor: const Color(0xFF012D1D),
                                disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
                                disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(32),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call_made_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tarik Saldo ke Rekening',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 2. ESCROW CARD (SALDO TERTAHAN) ---
                  FadeInUp(
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE8F0EB), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF4DB),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.lock_clock_rounded,
                                  color: Color(0xFF9A6700),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Saldo Tertahan (Escrow)',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF012D1D),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Dana ditahan selama 24 jam untuk perlindungan dispute',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 11,
                                        fontWeight: FontWeight.normal,
                                        color: Color(0xFF717973),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Jumlah Tertahan:',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF414844),
                                ),
                              ),
                              Text(
                                _formatRupiah(_escrowBalance),
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9A6700),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // --- 3. TRANSACTION HISTORY SECTION ---
                  const Text(
                    'Riwayat Transaksi Dompet',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _history.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.history_toggle_off_rounded,
                                size: 48,
                                color: const Color(0xFF012D1D).withValues(alpha: 0.15),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Belum ada riwayat transaksi',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  color: Color(0xFF717973),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          separatorBuilder: (context, _) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final log = _history[index];
                            final isEarning = log['type'] == 'earning';
                            return SubtleFadeIn(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Icon indicator
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isEarning
                                            ? const Color(0xFFE9F7EF)
                                            : const Color(0xFFFDECEC),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isEarning
                                            ? Icons.call_received_rounded
                                            : Icons.call_made_rounded,
                                        color: isEarning
                                            ? const Color(0xFF1B7F4C)
                                            : const Color(0xFFB42318),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    // Details text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            log['title']!,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF012D1D),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            log['date']!,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 11,
                                              color: Color(0xFF717973),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Amount
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${isEarning ? '+' : '-'}${_formatRupiah(log['amount'])}',
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isEarning
                                                ? const Color(0xFF1B7F4C)
                                                : const Color(0xFFB42318),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFFF8EF),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: const Color(0xFFD6C7A1).withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            log['status']!,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF012D1D),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────
// WITHDRAWAL BOTTOM SHEET WIDGET
// ─────────────────────────────────────────────
class _WithdrawBottomSheet extends StatefulWidget {
  final double maxBalance;
  final Function(double) onWithdrawSuccess;

  const _WithdrawBottomSheet({
    required this.maxBalance,
    required this.onWithdrawSuccess,
  });

  @override
  State<_WithdrawBottomSheet> createState() => _WithdrawBottomSheetState();
}

class _WithdrawBottomSheetState extends State<_WithdrawBottomSheet> {
  final _amountController = TextEditingController();
  final _accountController = TextEditingController();
  String _selectedBank = 'BCA';
  String? _errorMessage;
  bool _isSubmitting = false;

  final List<String> _banks = [
    'BCA',
    'Bank Mandiri',
    'BNI',
    'BRI',
    'GoPay (E-Wallet)',
    'OVO (E-Wallet)',
    'ShopeePay (E-Wallet)',
  ];

  @override
  void dispose() {
    _amountController.dispose();
    _accountController.dispose();
    super.dispose();
  }

  void _selectAmount(double value) {
    setState(() {
      _amountController.text = value.toStringAsFixed(0);
      _errorMessage = null;
    });
  }

  void _submitWithdrawal() {
    final amountText = _amountController.text.trim();
    final accountText = _accountController.text.trim();
    
    if (amountText.isEmpty || accountText.isEmpty) {
      setState(() => _errorMessage = 'Mohon lengkapi nominal dan nomor rekening');
      return;
    }

    final double? amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Nominal penarikan tidak valid');
      return;
    }

    if (amount < 20000) {
      setState(() => _errorMessage = 'Minimal penarikan adalah Rp. 20.000');
      return;
    }

    if (amount > widget.maxBalance) {
      setState(() => _errorMessage = 'Saldo aktif Anda tidak mencukupi');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Simulate API delay for cashout
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      
      // Close Keyboard & BottomSheet
      Navigator.pop(context);
      
      // Callback to update parent widget state
      widget.onWithdrawSuccess(amount);
      
      // Show Success Dialog
      _showSuccessDialog();
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Center(
        child: ZoomIn(
          duration: const Duration(milliseconds: 400),
          child: AlertDialog(
            backgroundColor: const Color(0xFFFFF8EF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE9F7EF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF1B7F4C),
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Pencairan Diajukan!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Permintaan pencairan saldo berhasil diajukan. Admin akan memproses transfer dana ke rekening Anda dalam waktu 1x24 jam.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xFF717973),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF012D1D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                      child: const Text(
                        'Mengerti',
                        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardHeight),
      decoration: const BoxDecoration(
        color: Color(0xFFFFF8EF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6C7A1).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tarik Saldo',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF012D1D),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown bank
            const Text(
              'Tujuan Bank / E-Wallet',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF717973),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8E4DE), width: 1.5),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedBank,
                  isExpanded: true,
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF012D1D)),
                  items: _banks.map((bank) => DropdownMenuItem(
                    value: bank,
                    child: Text(
                      bank,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  )).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedBank = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Account number input
            const Text(
              'Nomor Rekening / HP',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF717973),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _accountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF012D1D),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Masukkan nomor rekening tujuan...',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8E4DE), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF012D1D), width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount input
            const Text(
              'Nominal Penarikan (Rupiah)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF717973),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF012D1D),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                prefixText: 'Rp. ',
                prefixStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012D1D),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                hintText: 'Minimal 20.000',
                hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.normal, color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8E4DE), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF012D1D), width: 1.8),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Quick select chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildQuickSelectChip('Rp. 50k', 50000),
                  const SizedBox(width: 8),
                  _buildQuickSelectChip('Rp. 100k', 100000),
                  const SizedBox(width: 8),
                  _buildQuickSelectChip('Rp. 200k', 200000),
                  const SizedBox(width: 8),
                  _buildQuickSelectChip('Tarik Semua', widget.maxBalance),
                ],
              ),
            ),
            
            // Error Message Display
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFFB42318),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitWithdrawal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF012D1D),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF012D1D).withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Konfirmasi Pencairan',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectChip(String label, double val) {
    if (val <= 0 || val > widget.maxBalance) return const SizedBox.shrink();
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.white,
      shadowColor: Colors.black.withValues(alpha: 0.05),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8E4DE), width: 1),
      ),
      labelStyle: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF012D1D),
      ),
      onPressed: () => _selectAmount(val),
    );
  }
}
