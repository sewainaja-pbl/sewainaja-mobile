import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'return_item_scan_screen.dart';
import 'owner_return_show_qr_screen.dart';
import 'adendum_screen.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/transaction_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class RentalDeadlineScreen extends StatefulWidget {
  final String? transactionId;
  const RentalDeadlineScreen({super.key, this.transactionId});

  @override
  State<RentalDeadlineScreen> createState() => _RentalDeadlineScreenState();
}

class _RentalDeadlineScreenState extends State<RentalDeadlineScreen> {
  final TransactionRepository _repository = TransactionRepository();
  bool _isLoading = false;
  String? _errorMessage;
  TransactionModel? _transaction;
  Timer? _timer;
  Duration _remainingDuration = Duration.zero;
  LatLng _itemLocation = const LatLng(-6.966667, 110.416664);
  String _itemAddressLabel = 'Lokasi Barang';
  @override
  void initState() {
    super.initState();
    _fetchTransaction();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchTransaction() async {
    final tId = widget.transactionId;
    if (tId == null || tId.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = 'ID Transaksi tidak valid';
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final transaction = await _repository.fetchTransactionById(tId);
      if (mounted) {
        setState(() {
          _transaction = transaction;
          _isLoading = false;
        });

        final detail = transaction.details.isNotEmpty ? transaction.details.first : null;
        if (detail?.endDate != null) {
          _startTimer(detail!.endDate!);
        }

        if (detail?.itemId != null) {
          _fetchItemLocation(detail!.itemId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchItemLocation(String itemId) async {
    try {
      final itemDoc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
      if (itemDoc.exists && mounted) {
        final data = itemDoc.data();
        final address = data?['address'] as Map<String, dynamic>?;
        final label = address?['label']?.toString() ?? address?['fullAddress']?.toString() ?? 'Lokasi Barang';
        final coordinat = address?['coordinat'] as Map<String, dynamic>?;
        if (coordinat != null) {
          final lat = (coordinat['latitude'] as num?)?.toDouble();
          final lng = (coordinat['longitude'] as num?)?.toDouble();
          if (lat != null && lng != null) {
            setState(() {
              _itemLocation = LatLng(lat, lng);
              _itemAddressLabel = label;
            });
          }
        }
      }
    } catch (_) {
      // Silently ignore
    }
  }

  void _startTimer(DateTime endDate) {
    _timer?.cancel();
    final now = DateTime.now();
    setState(() {
      _remainingDuration = endDate.isAfter(now) ? endDate.difference(now) : Duration.zero;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentNow = DateTime.now();
      if (currentNow.isAfter(endDate)) {
        if (mounted) {
          setState(() {
            _remainingDuration = Duration.zero;
          });
        }
        _timer?.cancel();
      } else {
        if (mounted) {
          setState(() {
            _remainingDuration = endDate.difference(currentNow);
          });
        }
      }
    });
  }

  String _formatDate(dynamic dt) {
    if (dt == null) return '-';
    if (dt is! DateTime) return '-';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final hourStr = dt.hour.toString().padLeft(2, '0');
    final minStr = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} • $hourStr:$minStr';
  }

  String _formatDateShort(dynamic dt) {
    if (dt == null) return '';
    if (dt is! DateTime) return '';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  double _getProgress(DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) return 0.0;
    final total = endDate.difference(startDate).inMilliseconds;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(startDate).inMilliseconds;
    if (elapsed <= 0) return 0.0;
    if (elapsed >= total) return 1.0;
    return elapsed / total;
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
    final startDate = detail?.startDate;
    final endDate = detail?.endDate;

    final days = _remainingDuration.inDays;
    final hours = _remainingDuration.inHours % 24;
    final minutes = _remainingDuration.inMinutes % 60;
    final seconds = _remainingDuration.inSeconds % 60;

    final daysStr = days.toString().padLeft(2, '0');
    final hoursStr = hours.toString().padLeft(2, '0');
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');

    final progress = _getProgress(startDate, endDate);
    final flexElapsed = (progress * 100).toInt();
    final flexRemaining = 100 - flexElapsed;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFDF9F4),
        centerTitle: true,
        title: const Text(
          'Tenggat',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.transactionId != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Color(0xFF012D1D)),
              onPressed: _fetchTransaction,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFC1C8C2),
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Countdown Timer Card
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2F6743),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text(
                    'Sisa Waktu',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFFFFF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (days > 0) ...[
                          _buildTimerBlock(daysStr, 'Hari'),
                          _buildSeparator(),
                        ],
                        if (days > 0 || hours > 0) ...[
                          _buildTimerBlock(hoursStr, 'Jam'),
                          _buildSeparator(),
                        ],
                        _buildTimerBlock(minutesStr, 'Menit'),
                        _buildSeparator(),
                        _buildTimerBlock(secondsStr, 'Detik'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Time progress details
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      startDate != null ? '${_formatDateShort(startDate)} (Mulai)' : '- (Mulai)',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF414844),
                      ),
                    ),
                    Text(
                      endDate != null ? '${_formatDateShort(endDate)} (Selesai)' : '- (Selesai)',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF414844),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCD8D3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      if (flexElapsed > 0)
                        Expanded(
                          flex: flexElapsed,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF2F6743), Color(0xFFA2D7B4)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      if (flexRemaining > 0)
                        Expanded(
                          flex: flexRemaining,
                          child: const SizedBox(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Timeline
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF414844),
                  ),
                ),
                const SizedBox(height: 16),
                if (_transaction != null) ...[
                  if (_transaction!.status.toLowerCase() == 'ongoing' && _remainingDuration == Duration.zero)
                    _buildTimelineItem('Sewa berakhir / Overdue', const Color(0xFFBA1A1A))
                  else if (_transaction!.status.toLowerCase() == 'ongoing')
                    _buildTimelineItem('Sewa Aktif (Sedang Berjalan)', const Color(0xFFF8BD00))
                  else if (_transaction!.status.toLowerCase() == 'completed')
                    _buildTimelineItem('Sewa Selesai (Barang Kembali)', const Color(0xFF2F6743)),
                  
                  const SizedBox(height: 12),
                  if (_transaction!.checkinAt != null) ...[
                    _buildTimelineItem('Serah terima berhasil • ${_formatDate(_transaction!.checkinAt)}', const Color(0xFF2F6743)),
                    const SizedBox(height: 12),
                  ],
                  if (_transaction!.updatedAt != null) ...[
                    _buildTimelineItem('Request sewa disetujui pemilik • ${_formatDate(_transaction!.updatedAt)}', const Color(0xFF2F6743)),
                    const SizedBox(height: 12),
                  ],
                  _buildTimelineItem('Request sewa diajukan • ${_formatDate(_transaction!.createdAt)}', const Color(0xFF2F6743)),
                ] else ...[
                  _buildTimelineItem('Memuat data sewa...', const Color(0xFFC1C8C2)),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Item Card Details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: itemPhoto.isNotEmpty
                        ? (itemPhoto.startsWith('http')
                            ? Image.network(
                                itemPhoto,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                itemPhoto,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              ))
                        : Container(
                            width: 60,
                            height: 60,
                            color: const Color(0xFFFFF3CD),
                            child: const Center(
                              child: Icon(Icons.image, color: Color(0xFF856404)),
                            ),
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pemilik: $ownerName',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF414844),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          startDate != null && endDate != null
                              ? '${_formatDateShort(startDate)} - ${_formatDateShort(endDate)}'
                              : '-',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Color(0xFF414844),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Location Map
            _buildLocationMap(),
            const SizedBox(height: 32),

            // Bottom Actions
            _buildBottomActions(context, itemName, ownerName, itemPhoto, startDate, endDate),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBlock(String value, String label) {
    return Column(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF012D1D),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFF8EF),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF012D1D),
        ),
      ),
    );
  }

  Widget _buildLocationMap() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            key: ValueKey(_itemLocation),
            height: 150,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _itemLocation,
                initialZoom: 14,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sewainaja.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _itemLocation,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF012D1D),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              _itemAddressLabel,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(
    BuildContext context,
    String itemName,
    String ownerName,
    String itemPhoto,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final isRenter = _transaction == null || currentUser?.uid == _transaction?.renterId;

    if (!isRenter) {
      return _buildActionButton(
        'Scan QR Pengembalian',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReturnItemScanScreen(
                transactionId: widget.transactionId,
                itemName: itemName,
              ),
            ),
          ).then((_) => _fetchTransaction());
        },
      );
    }

    return Column(
      children: [
        _buildActionButton(
          'Kembalikan',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OwnerReturnShowQRScreen(
                  transactionId: widget.transactionId,
                  itemData: {
                    'title': itemName,
                    'owner': 'Pemilik: $ownerName',
                    'date': startDate != null && endDate != null
                        ? '${_formatDateShort(startDate)} - ${_formatDateShort(endDate)}'
                        : '-',
                    'image': itemPhoto,
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Request Perpanjangan',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdendumScreen(transactionId: widget.transactionId),
              ),
            );
          },
        ),

      ],
    );
  }

  Widget _buildActionButton(String text, {VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed ?? () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFF012D1D), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332),
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineItem(String text, Color dotColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              color: Color(0xFF414844),
            ),
          ),
        ),
      ],
    );
  }
}
