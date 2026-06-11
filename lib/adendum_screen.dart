import 'package:flutter/material.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/transaction_repository.dart';

class AdendumScreen extends StatefulWidget {
  final String? transactionId;
  const AdendumScreen({super.key, this.transactionId});

  @override
  State<AdendumScreen> createState() => _AdendumScreenState();
}

class _AdendumScreenState extends State<AdendumScreen> {
  final TransactionRepository _repository = TransactionRepository();
  bool _isLoading = false;
  String? _errorMessage;
  TransactionModel? _transaction;

  DateTime? _newEndDate;
  bool _isSubmitting = false;
  String _selectedPaymentMethod = 'midtrans';

  @override
  void initState() {
    super.initState();
    _fetchTransaction();
  }

  Future<void> _fetchTransaction() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      // Set up mock data for preview/standalone
      setState(() {
        _newEndDate = DateTime.now().add(const Duration(days: 1));
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transaction = await _repository.fetchTransactionById(tId);
      setState(() {
        _transaction = transaction;
        _isLoading = false;
        final detail = transaction.details.isNotEmpty ? transaction.details.first : null;
        if (detail?.endDate != null) {
          _newEndDate = detail!.endDate!.add(const Duration(days: 1));
        } else {
          _newEndDate = DateTime.now().add(const Duration(days: 1));
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDateShort(DateTime? dt) {
    if (dt == null) return '-';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '-';
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '$hourStr:$minStr';
  }

  Future<void> _selectEndDate(BuildContext context, DateTime currentEnd) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _newEndDate!.isAfter(currentEnd) ? _newEndDate! : currentEnd.add(const Duration(hours: 1)),
      firstDate: currentEnd,
      lastDate: currentEnd.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF012D1D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF012D1D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _newEndDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _newEndDate?.hour ?? currentEnd.hour,
          _newEndDate?.minute ?? currentEnd.minute,
        );
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context, DateTime currentEnd) async {
    final initialTime = TimeOfDay.fromDateTime(_newEndDate ?? currentEnd);
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF012D1D),
              onPrimary: Colors.white,
              onSurface: Color(0xFF012D1D),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final baseDate = _newEndDate ?? currentEnd;
        _newEndDate = DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _submitRequest(double extensionPrice) async {
    if (widget.transactionId == null || widget.transactionId!.isEmpty || widget.transactionId == 'dummy_trans_123') {
      // Allow dummy flow
    } else {
      setState(() {
        _isSubmitting = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF012D1D)),
        ),
      );

      try {
        final detail = _transaction?.details.isNotEmpty == true ? _transaction!.details.first : null;
        final currentEnd = detail?.endDate ?? DateTime.now().add(const Duration(days: 1));
        final newEnd = _newEndDate ?? currentEnd.add(const Duration(days: 1));
        
        await _repository.requestAdendum(widget.transactionId!, newEnd, extensionPrice, _selectedPaymentMethod);
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          setState(() {
            _isSubmitting = false;
          });

          // Show success dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFFFFF8EF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'Permintaan Terkirim',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012D1D),
                ),
              ),
              content: const Text(
                'Permintaan perpanjangan sewa Anda telah berhasil diajukan ke pemilik barang. Silakan tunggu konfirmasi.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Color(0xFF414844),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Pop dialog
                    Navigator.pop(context); // Pop AdendumScreen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF012D1D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Kembali',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          setState(() {
            _isSubmitting = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
        }
      }
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF012D1D)),
      ),
    );

    // Simulate API request call
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      setState(() {
        _isSubmitting = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFFF8EF),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text(
            'Permintaan Terkirim',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Color(0xFF012D1D),
            ),
          ),
          content: const Text(
            'Permintaan perpanjangan sewa Anda telah berhasil diajukan ke pemilik barang. Silakan tunggu konfirmasi.',
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFF414844),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Pop dialog
                Navigator.pop(context); // Pop AdendumScreen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  onPressed: _fetchTransaction,
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

    final detail = _transaction?.details.isNotEmpty == true ? _transaction!.details.first : null;
    final itemName = detail?.itemNameSnapshot ?? 'Sony Camera a6000';
    final ownerName = _transaction?.ownerName ?? 'Han so Hee';
    final itemPhoto = detail?.itemPhotoUrlSnapshot ?? '';
    final pricePerHour = detail?.priceAtBooking ?? 15000.0;
    
    // Original End Date (Default start of extension)
    final currentEnd = detail?.endDate ?? DateTime.now().add(const Duration(days: 1));
    // New End Date
    final newEnd = _newEndDate ?? currentEnd.add(const Duration(days: 1));

    // Calculate hours of extension
    int totalHours = newEnd.difference(currentEnd).inHours;
    if (totalHours < 0) totalHours = 0;
    final extensionPrice = totalHours * pricePerHour;

    String durationText = "-";
    if (totalHours >= 24) {
      final days = (totalHours / 24).ceil();
      durationText = "$days Hari ($totalHours Jam)";
    } else {
      durationText = "$totalHours Jam";
    }

    final priceStr = "Rp. ${pricePerHour.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/jam";
    final costStr = "Rp. ${extensionPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}";

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFDF9F4),
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
          'Adendum',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 26,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFC1C8C2).withOpacity(0.5),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PRODUCT CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                    borderRadius: BorderRadius.circular(16.0),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        image: itemPhoto.isNotEmpty && (itemPhoto.startsWith('http') || itemPhoto.startsWith('assets/'))
                            ? DecorationImage(
                                image: itemPhoto.startsWith('http')
                                    ? NetworkImage(itemPhoto)
                                    : AssetImage(itemPhoto) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (itemPhoto.isEmpty || (!itemPhoto.startsWith('http') && !itemPhoto.startsWith('assets/')))
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
                        Row(
                          children: [
                            const Text(
                              'PRODUK DISEWA',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7B5804),
                                letterSpacing: 1.2,
                              ),
                            ),
                            if (widget.transactionId == null || widget.transactionId!.isEmpty || widget.transactionId == 'dummy_trans_123')
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFECEB),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: const Color(0xFFF04438), width: 0.5),
                                ),
                                child: const Text(
                                  'DUMMY',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF04438),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF012D1D),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          priceStr,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
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
            
            // 2. SECTION TITLE
            const Row(
              children: [
                Icon(Icons.calendar_today_outlined, color: Color(0xFF012D1D), size: 20),
                SizedBox(width: 8),
                Text(
                  'Tentukan Durasi Perpanjangan Sewa',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 3. DATE AND TIME PICKERS
            Row(
              children: [
                Expanded(
                  child: _buildPickerField(
                    'Mulai',
                    _formatDateShort(currentEnd),
                    isReadOnly: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildPickerField(
                    'Selesai',
                    _formatDateShort(newEnd),
                    onTap: () => _selectEndDate(context, currentEnd),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPickerField(
              'Jam kembali',
              _formatTime(newEnd),
              onTap: () => _selectEndTime(context, currentEnd),
            ),
            
            const SizedBox(height: 24),
            
            // 4. TOTAL DURATION
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F5E9),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: Color(0xFF012D1D),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.timer_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Durasi Perpanjangan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  ),
                  Text(
                    durationText,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 5. PRICE DETAILS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
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
                  const Text(
                    'Rincian Biaya Perpanjangan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Biaya Sewa ($totalHours Jam)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF5C635E),
                        ),
                      ),
                      Text(
                        costStr,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(color: Color(0xFFEEEEEE), thickness: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Harga',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                      Text(
                        costStr,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Payment Method Selection
            const Row(
              children: [
                Icon(Icons.payment_outlined, color: Color(0xFF012D1D), size: 20),
                SizedBox(width: 8),
                Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = 'midtrans';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'midtrans' ? const Color(0xFFE9F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'midtrans' ? const Color(0xFF012D1D) : const Color(0xFFC1C8C2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.credit_card_outlined,
                            color: _selectedPaymentMethod == 'midtrans' ? const Color(0xFF012D1D) : const Color(0xFF5C635E),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Cashless',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedPaymentMethod == 'midtrans' ? const Color(0xFF012D1D) : const Color(0xFF5C635E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedPaymentMethod = 'cash';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      decoration: BoxDecoration(
                        color: _selectedPaymentMethod == 'cash' ? const Color(0xFFE9F5E9) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedPaymentMethod == 'cash' ? const Color(0xFF012D1D) : const Color(0xFFC1C8C2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.monetization_on_outlined,
                            color: _selectedPaymentMethod == 'cash' ? const Color(0xFF012D1D) : const Color(0xFF5C635E),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Tunai (COD)',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _selectedPaymentMethod == 'cash' ? const Color(0xFF012D1D) : const Color(0xFF5C635E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
 
            // 6. ACTION BUTTON
            ElevatedButton(
              onPressed: _isSubmitting || totalHours <= 0 ? null : () => _submitRequest(extensionPrice),
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
                'Kirim Request Perpanjangan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerField(String label, String value, {VoidCallback? onTap, bool isReadOnly = false}) {
    return GestureDetector(
      onTap: isReadOnly ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isReadOnly ? const Color(0xFFF7F3EE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5C635E),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF012D1D),
                  ),
                ),
                if (!isReadOnly)
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xFF5C635E),
                    size: 18,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
