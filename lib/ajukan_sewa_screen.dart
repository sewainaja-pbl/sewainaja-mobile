import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'map_common_widgets.dart';
import 'widgets/success_rental_modal.dart';
import 'api_config.dart';
import 'auth_session_service.dart';
import 'app_feedback.dart';
import 'image_upload_service.dart';
import 'profile_sync_service.dart';
import 'ktp_upload_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AjukanSewaScreen extends StatefulWidget {
  final Map<String, dynamic>? itemData;
  const AjukanSewaScreen({super.key, this.itemData});

  @override
  State<AjukanSewaScreen> createState() => _AjukanSewaScreenState();
}

class _AjukanSewaScreenState extends State<AjukanSewaScreen> {
  final AuthSessionService _authSessionService = const AuthSessionService();
  final ImageUploadService _imageUploadService = ImageUploadService();

  LatLng _itemLocation = const LatLng(-6.9791, 110.4208);
  String _itemAddressLabel = 'Lokasi tidak diketahui';

  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  bool _isSubmitting = false;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoadingStatus = true;
  String _userStatus = 'unverified';

  @override
  void initState() {
    super.initState();
    _loadUserStatus();
    // Default: Start tomorrow, end in 3 days, both at 19:00
    final now = DateTime.now();
    _startDate = now.add(const Duration(days: 1));
    _startTime = const TimeOfDay(hour: 19, minute: 0);
    _endDate = now.add(const Duration(days: 3));
    _endTime = const TimeOfDay(hour: 19, minute: 0);

    // Initialize location from itemData
    if (widget.itemData != null) {
      final address = widget.itemData!['address'] as Map<String, dynamic>?;
      _itemAddressLabel = address?['label']?.toString() ?? address?['fullAddress']?.toString() ?? 'Lokasi pemilik barang';
      final coordinat = address?['coordinat'] as Map<String, dynamic>?;
      if (coordinat != null) {
        final lat = (coordinat['latitude'] as num?)?.toDouble();
        final lng = (coordinat['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          _itemLocation = LatLng(lat, lng);
        }
      }
    }
  }

  Future<void> _loadUserStatus() async {
    try {
      final cached = await const ProfileSyncService().readCachedProfile();
      if (mounted) {
        setState(() {
          _userStatus = cached.status.toLowerCase();
          _isLoadingStatus = false;
        });
      }
      final synced = await const ProfileSyncService().syncProfileFromApi(forceRefreshToken: false);
      if (synced != null && mounted) {
        setState(() {
          _userStatus = synced.status.toLowerCase();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingStatus = false);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  int get _totalHours {
    if (_startDate == null || _startTime == null || _endDate == null || _endTime == null) {
      return 0;
    }
    final startDateTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTime!.hour,
      _startTime!.minute,
    );
    final endDateTime = DateTime(
      _endDate!.year,
      _endDate!.month,
      _endDate!.day,
      _endTime!.hour,
      _endTime!.minute,
    );
    if (endDateTime.isBefore(startDateTime)) {
      return 0;
    }
    return endDateTime.difference(startDateTime).inHours;
  }

  int get _totalDays {
    final hours = _totalHours;
    if (hours <= 0) return 0;
    return (hours / 24).ceil();
  }

  double get _totalPrice {
    final priceRaw = widget.itemData?['pricePerHour'] ?? 15000.0;
    final priceVal = (priceRaw as num).toDouble();
    return _totalHours * priceVal;
  }

  String _formatCurrency(double val) {
    return val.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    final months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '-';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        // Adjust end date if it becomes before start date
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate!.add(const Duration(days: 2));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()).add(const Duration(days: 2)),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;
    final hours = _totalHours;
    if (hours <= 0) {
      showAppErrorSnack(context, 'Durasi sewa tidak valid (harus lebih dari 0 jam).');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final token = await _authSessionService.getValidIdToken();
      final itemId = widget.itemData?['id']?.toString() ?? '';
      
      final startDateTime = DateTime(
        _startDate!.year,
        _startDate!.month,
        _startDate!.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      final endDateTime = DateTime(
        _endDate!.year,
        _endDate!.month,
        _endDate!.day,
        _endTime!.hour,
        _endTime!.minute,
      );

      final body = {
        'items': [
          {
            'itemId': itemId,
            'startDate': startDateTime.toUtc().toIso8601String(),
            'endDate': endDateTime.toUtc().toIso8601String(),
          }
        ]
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/transactions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      final respData = jsonDecode(response.body);
      if (response.statusCode == 200 && respData['success'] == true) {
        if (!mounted) return;
        SuccessRentalModal.show(context);
      } else {
        final errMsg = respData['error']?['message']?.toString() ?? 'Gagal mengajukan sewa';
        if (!mounted) return;
        showAppErrorSnack(context, errMsg);
      }
    } catch (e) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Terjadi kesalahan koneksi.');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingStatus) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8EF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF012D1D)),
        ),
      );
    }

    if (_userStatus != 'verified') {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF8EF),
        appBar: AppBar(
          backgroundColor: const Color(0xFFFFF8EF),
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          centerTitle: true,
          leadingWidth: 90,
          leading: Padding(
            padding: const EdgeInsets.only(left: 24, top: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF012D1D),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: Color(0xFFFFF8EF),
                    ),
                  ),
                ),
              ),
            ),
          ),
          title: const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              "Ajukan Sewa",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF012D1D),
              ),
            ),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_userStatus == 'pending') ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF4DB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF9A6700),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verifikasi Sedang Diproses',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Dokumen identitas Anda sedang ditinjau oleh Admin. Harap tunggu hingga akun Anda disetujui untuk dapat mengajukan sewa barang.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFF5C635E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Developer Demo Box
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDECEC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF5B7B1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.bug_report_outlined, color: Color(0xFFB42318), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'DEVELOPMENT TOOLS',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFB42318),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tekan tombol di bawah untuk mensimulasikan persetujuan instan dari admin dan melanjutkan.',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFF7B241C),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () async {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('user_status', 'verified');
                            final cached = await const ProfileSyncService().readCachedProfile();
                            final updated = CachedUserProfile(
                              name: cached.name,
                              email: cached.email,
                              phone: cached.phone,
                              profilePhotoUrl: cached.profilePhotoUrl,
                              status: 'verified',
                            );
                            await const ProfileSyncService().saveProfileToCache(updated, notify: true);
                            if (!context.mounted) return;
                            setState(() {
                              _userStatus = 'verified';
                            });
                            showAppSuccessSnack(context, 'Simulasi: Akun berhasil diverifikasi!');
                          },
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFFB42318),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text(
                                'Simulasikan Approve Admin (Dev)',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF4DB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.gpp_maybe_rounded,
                      color: Color(0xFF9A6700),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Verifikasi KTP Diperlukan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Untuk alasan keamanan, Anda harus melakukan verifikasi KTP terlebih dahulu sebelum dapat menyewa barang di marketplace.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 13,
                      color: Color(0xFF5C635E),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GestureDetector(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => KtpUploadScreen(
                            onVerificationCompleted: () {
                              if (mounted) {
                                setState(() {
                                  _userStatus = 'verified';
                                });
                              }
                            },
                          ),
                        ),
                      );
                      _loadUserStatus();
                    },
                    child: Container(
                      height: 56,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF012D1D),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Center(
                        child: Text(
                          'Verifikasi Sekarang',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF012D1D)),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Center(
                      child: Text(
                        'Kembali',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(
        0xFFFDF9F4,
      ), // Background Utama ID: '300:1159'
      // --- SECTION 1: APPBAR / HEADER ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        centerTitle: true,
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFF012D1D),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: Color(0xFFFDF9F4),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Ajukan",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF012D1D),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF012D1D).withValues(alpha: 0),
                  const Color(0xFF012D1D).withValues(alpha: 0.28),
                  const Color(0xFF012D1D).withValues(alpha: 0),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),
      ),

      // --- MAIN BODY (Section 2 - 6) ---
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ### [SECTION 2: ITEM SUMMARY CARD]
            _buildItemSummaryCard(),
            const SizedBox(height: 32),

            // ### [SECTION 3: TENTUKAN DURASI SEWA (FORM GRID)]
            _buildDurationFormGrid(),
            const SizedBox(height: 32),

            // ### [SECTION 4: TOTAL DURASI INDICATOR]
            _buildTotalDurationIndicator(),
            const SizedBox(height: 32),

            // ### [SECTION 5: PETA LOKASI BARANG]
            _buildLocationMap(),
            const SizedBox(height: 32),

            // ### [SECTION 6: RINCIAN HARGA (PRICE BREAKDOWN)]
            _buildPriceBreakdownCard(),
            const SizedBox(height: 32),

            // ### [SECTION 7: CATATAN TAMBAHAN (TEXTAREA)]
            _buildAdditionalNotesField(),

            // Padding bottom extra agar konten tidak tertutup bottom navigation bar
            const SizedBox(height: 40),
          ],
        ),
      ),

      // --- ### [SECTION 7: BOTTOM ACTION BAR (CHECKOUT)] ---
      bottomNavigationBar: _buildBottomCheckoutBar(),
    );
  }

  // --- SECTION 2: PETA LOKASI BARANG ---
  Widget _buildLocationMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons
                  .location_on_rounded, // Alternative fallback for boxicons:location
              size: 20,
              color: Color(0xFF012D1D),
            ),
            SizedBox(width: 8),
            Text(
              "Lokasi Barang", // ID: '300:1161'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF012D1D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10), // Smooth padded map look
          decoration: BoxDecoration(
            color: Colors.white, // ID: '300:1163' Fills: #FFFFFF
            borderRadius: BorderRadius.circular(30), // BorderRadius: 30px
            border: Border.all(
              color: const Color(
                0xFF1B4332,
              ).withValues(alpha: 0.5), // Outline: #1B4332 0.5px
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              25,
            ), // ID: '300:1166' -> BorderRadius: 25px
            child: ReusableMapCard(
              center: _itemLocation,
              zoom: 14,
              interactive: true,
              showCenterPin: false,
              markers: [MapMarkerData(point: _itemLocation, highlighted: true)],
              overlayLabel: _itemAddressLabel,
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 3: ITEM SUMMARY CARD ---
  Widget _buildItemSummaryCard() {
    final category = widget.itemData?['categoryName']?.toString() ?? 'Camera';
    final name = widget.itemData?['name']?.toString() ?? 'Sony a6000 Body Only';
    final priceRaw = widget.itemData?['pricePerHour'] ?? 15000.0;
    final priceVal = (priceRaw as num).toDouble();
    final photos = widget.itemData?['photos'] as List<dynamic>? ?? [];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // Background: #FFFFFF
        borderRadius: BorderRadius.circular(
          30,
        ), // Specs recommended up to 40px, making it smooth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: photos.isEmpty
                    ? const AssetImage('assets/images/Iklan.jpg')
                    : _imageUploadService.buildImageProvider(photos.first.toString(), targetWidth: 200),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Category
                Text(
                  category,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800, // ExtraBold/Bold
                    fontSize: 11,
                    color: Color(0xFF7B5804), // Gold/Brown
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                // Title
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700, // Bold
                    fontSize: 18,
                    height: 1.2,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 8),
                // Price
                Text(
                  "Rp. ${_formatCurrency(priceVal)},00/jam",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500, // Medium
                    fontSize: 14,
                    color: Color(0xFF7B5804),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 3: TENTUKAN DURASI SEWA (FORM GRID) ---
  Widget _buildDurationFormGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Title
        Row(
          children: const [
            FaIcon(
              FontAwesomeIcons.calendarDays,
              size: 18,
              color: Color(0xFF012D1D),
            ),
            SizedBox(width: 10),
            Text(
              "Tentukan Durasi Sewa",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600, // SemiBold
                fontSize: 18,
                color: Color(0xFF012D1D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // GRID 2x2 for Duration Inputs using a simple Wrap/Row solution
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectStartDate,
                child: _buildInputBox(label: "Mulai", value: _formatDate(_startDate)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _selectEndDate,
                child: _buildInputBox(label: "Selesai", value: _formatDate(_endDate)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _selectStartTime,
                child: _buildInputBox(label: "Jam ambil", value: _formatTime(_startTime)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _selectEndTime,
                child: _buildInputBox(label: "Jam kembali", value: _formatTime(_endTime)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper Component for Duration Form Grid
  Widget _buildInputBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF585D59), // Color_Text_Muted
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF012D1D), // Value Color
                ),
              ),
            ],
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Color(0xFF585D59),
          ),
        ],
      ),
    );
  }

  // --- SECTION 4: TOTAL DURASI INDICATOR ---
  Widget _buildTotalDurationIndicator() {
    final days = _totalDays;
    final hours = _totalHours;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFC1ECD4), // Pale Mint Background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Number Circle Indicator
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF012D1D), // Deep Forest
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                "$days",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text Label and Value
          const Text(
            "Total Durasi Sewa:",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500, // Medium
              fontSize: 14,
              color: Color(0xFF012D1D),
            ),
          ),
          const Spacer(),
          Text(
            "$days Hari ($hours Jam)",
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700, // Bold
              fontSize: 15,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // --- SECTION 5: RINCIAN HARGA (PRICE BREAKDOWN) ---
  Widget _buildPriceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // ID: '311:1686'
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            "Rincian Harga",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700, // Bold
              fontSize: 18,
              color: Color(0xFF1C1C19),
            ),
          ),
          const SizedBox(height: 20),

          // Price Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "Biaya Sewa ($_totalDays Hari / $_totalHours Jam)",
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF414844),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Rp. ${_formatCurrency(_totalPrice)}",
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1C1C19),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Custom Dotted Divider style line
          const Divider(
            color: Color(0xFFF1EDE8), // Color_Divider
            thickness: 1.5,
          ),

          const SizedBox(height: 16),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: const Text(
                  "Total Harga",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800, // ExtraBold
                    fontSize: 18,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Rp. ${_formatCurrency(_totalPrice)}",
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700, // SemiBold/Bold
                  fontSize: 18,
                  color: Color(0xFF012D1D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SECTION 6: CATATAN TAMBAHAN (TEXTAREA) ---
  Widget _buildAdditionalNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catatan Tambahan (Opsional)",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700, // Bold
            fontSize: 14,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 96, // Specified height 96px
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3EE), // Input variant background
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _notesController,
            maxLines: null, // multi line
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF012D1D),
            ),
            decoration: const InputDecoration(
              hintText: "Contoh: 'Tolong tambahkan charger baterai'",
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF717973), // Color_Text_Subtle
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 7: BOTTOM ACTION BAR (CHECKOUT) ---
  Widget _buildBottomCheckoutBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F4), // Background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left Price Display
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "TOTAL",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700, // Bold
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Color(0xFF414844),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Rp. ${_formatCurrency(_totalPrice)}",
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700, // Bold
                      fontSize: 18,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ],
              ),
            ),
            // Right Checkout Action Button
            GestureDetector(
              onTap: _isSubmitting ? null : _submitRequest,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D), // Background Deep Green
                  borderRadius: BorderRadius.circular(9999), // Full pill
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSubmitting)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    else
                      const Text(
                        "Kirim Request",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
