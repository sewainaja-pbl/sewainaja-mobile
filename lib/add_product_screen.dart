import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_common_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'app_feedback.dart';
import 'auth_session_service.dart';
import 'image_upload_service.dart';
import 'upload_image_policy.dart';
import 'widgets/add_item_success_modal.dart';
import 'data/models/item_model.dart';
import 'profile_sync_service.dart';
import 'ktp_upload_screen.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onBack;
  final ItemModel? editItem;
  const AddProductScreen({super.key, this.onBack, this.editItem});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  static const Color _fieldFillColor = Colors.white;
  static const Color _fieldBorderColor = Color(0xFFE6ECE8);
  static const Color _fieldHintColor = Color(0xFF717973);

  String? selectedCategoryId;
  String selectedKondisi = "Sangat Baik";
  String selectedDurasi = "Hari";
  LatLng _itemLocation = const LatLng(-6.966667, 110.416664);
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _useSavedAddress = true;
  String _customAddressLabel = 'Geser map untuk set titik barang';
  Timer? _debounceTimer;
  bool _isScrollEnabled = true;
  bool _isBootstrapping = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _addresses = const [];
  String? _selectedAddressId;
  final AuthSessionService _authSessionService = const AuthSessionService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final List<ProcessedImageFile> _productPhotos = [];
  List<String> _existingPhotos = [];
  String _userStatus = 'unverified';

  bool get isEditMode => widget.editItem != null;

  void _handleBack() {
    final didPop = Navigator.of(context).maybePop();
    didPop.then((popped) {
      if (!popped && widget.onBack != null) {
        widget.onBack!();
      }
    });
  }

  final List<String> kondisiList = ["Baru", "Sangat Baik", "Baik", "Cukup"];
  final List<String> durasiList = ["Jam", "Hari", "Minggu"];

  @override
  void initState() {
    super.initState();
    _bootstrapFormData();
  }

  Future<void> _bootstrapFormData() async {
    try {
      // Check user verification status
      try {
        final cached = await const ProfileSyncService().readCachedProfile();
        if (mounted) {
          setState(() {
            _userStatus = cached.status.toLowerCase();
          });
        }
        
        final synced = await const ProfileSyncService().syncProfileFromApi(forceRefreshToken: false);
        if (synced != null && mounted) {
          setState(() {
            _userStatus = synced.status.toLowerCase();
          });
        }
      } catch (e) {
        debugPrint('Error fetching verification status: $e');
      }

      final token = await _authSessionService.getValidIdToken();
      if (token == null || token.isEmpty) {
        if (mounted) {
          setState(() => _isBootstrapping = false);
        }
        _showSnack('Token login tidak ditemukan. Silakan login ulang.', true);
        return;
      }

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final responses = await Future.wait([
        http.get(
          Uri.parse('${ApiConfig.baseUrl}/categories'),
          headers: headers,
        ),
        http.get(Uri.parse('${ApiConfig.baseUrl}/addresses'), headers: headers),
      ]);

      final categoryResp = responses[0];
      final addressResp = responses[1];
      final categoryBody =
          jsonDecode(categoryResp.body) as Map<String, dynamic>;
      final addressBody = jsonDecode(addressResp.body) as Map<String, dynamic>;

      if (categoryResp.statusCode != 200 || categoryBody['success'] != true) {
        _showSnack('Gagal ambil data kategori.', true);
      }

      if (addressResp.statusCode != 200 || addressBody['success'] != true) {
        _showSnack('Gagal ambil data alamat.', true);
      }

      final categories = (categoryBody['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final addresses = (addressBody['data'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();

      Map<String, dynamic>? fullEditData;
      if (isEditMode) {
        final itemId = widget.editItem!.id;
        final detailsResp = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/items/$itemId'),
          headers: headers,
        );
        if (detailsResp.statusCode == 200) {
          final body = jsonDecode(detailsResp.body) as Map<String, dynamic>;
          if (body['success'] == true && body['data'] != null) {
            fullEditData = body['data'] as Map<String, dynamic>;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _categories = categories;
        _addresses = addresses;
        if (_categories.isNotEmpty) {
          selectedCategoryId = (_categories.first['id'] ?? '').toString();
        }
        if (_addresses.isNotEmpty) {
          _selectedAddressId = (_addresses.first['id'] ?? '').toString();
          _useSavedAddress = true;
          final coords = _extractLatLng(_addresses.first['coordinat']);
          if (coords != null) {
            _itemLocation = coords;
          }
        } else {
          _useSavedAddress = false;
        }

        if (isEditMode && fullEditData != null) {
          _nameController.text = fullEditData['name']?.toString() ?? '';
          _descriptionController.text = fullEditData['description']?.toString() ?? '';
          _priceController.text = (fullEditData['pricePerHour'] as num?)?.toStringAsFixed(0) ?? '';
          selectedCategoryId = fullEditData['categoryId']?.toString();
          selectedKondisi = _mapConditionFromApi(fullEditData['condition']?.toString() ?? 'fair');
          _existingPhotos = List<String>.from(fullEditData['photos'] ?? []);
          
          final address = fullEditData['address'] as Map<String, dynamic>?;
          final addressId = fullEditData['addressId'] ?? address?['id'];
          if (addressId != null) {
            _selectedAddressId = addressId.toString();
            _useSavedAddress = true;
          }
          final coords = _extractLatLng(address?['coordinat']);
          if (coords != null) {
            _itemLocation = coords;
          }
          if (address != null && address['fullAddress'] != null) {
            _customAddressLabel = address['fullAddress'].toString();
          }
        }
        _isBootstrapping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBootstrapping = false);
      _showSnack('Gagal mengambil data awal form.', true);
    }
  }

  String _mapConditionFromApi(String apiCond) {
    switch (apiCond.toLowerCase()) {
      case 'new':
        return 'Baru';
      case 'like-new':
        return 'Sangat Baik';
      case 'fair':
        return 'Baik';
      case 'poor':
        return 'Cukup';
      default:
        return 'Sangat Baik';
    }
  }

  LatLng? _extractLatLng(dynamic coordinateRaw) {
    if (coordinateRaw is Map<String, dynamic>) {
      final lat =
          (coordinateRaw['latitude'] ?? coordinateRaw['_latitude']) as num?;
      final lng =
          (coordinateRaw['longitude'] ?? coordinateRaw['_longitude']) as num?;
      if (lat != null && lng != null) {
        return LatLng(lat.toDouble(), lng.toDouble());
      }
    }
    return null;
  }

  void _onMapCameraMove(LatLng newCenter) {
    if (_useSavedAddress) return;
    setState(() {
      _itemLocation = newCenter;
    });
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () {
      _reverseGeocode();
    });
  }

  Future<void> _reverseGeocode() async {
    try {
      final uri = Uri.parse('https://nominatim.openstreetmap.org/reverse').replace(
        queryParameters: {
          'lat': _itemLocation.latitude.toString(),
          'lon': _itemLocation.longitude.toString(),
          'format': 'jsonv2',
          'zoom': '16',
        },
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'sewainaja-mobile/1.0 (add-product)'},
      );
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = (body['display_name'] ?? '').toString().trim();
      if (raw.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _customAddressLabel = _shortAddress(raw);
      });
    } catch (_) {}
  }

  String _shortAddress(String raw) {
    final parts = raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.length >= 3) {
      return '${parts[0]}, ${parts[1]}, ${parts[2]}';
    }
    return parts.isNotEmpty ? parts.join(', ') : 'Semarang, Jawa Tengah';
  }

  String _addressLabel(Map<String, dynamic> address) {
    final label = (address['label'] ?? '').toString().trim();
    final full = (address['fullAddress'] ?? '').toString().trim();
    if (label.isEmpty) return full;
    if (full.isEmpty) return label;
    return '$label • $full';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBootstrapping) {
      return const Scaffold(
        backgroundColor: Color(0xFFFDF9F4),
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
                onTap: _handleBack,
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
          title: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              isEditMode ? "Edit Barang" : "Tambah Barang",
              style: const TextStyle(
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
                    'Dokumen identitas Anda sedang ditinjau oleh Admin. Harap tunggu hingga akun Anda disetujui untuk dapat menambahkan barang ke marketplace.',
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
                    'Untuk alasan keamanan, Anda harus melakukan verifikasi KTP terlebih dahulu sebelum dapat menambahkan barang ke marketplace.',
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
                      _bootstrapFormData();
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
                  onTap: _handleBack,
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
      ), // Background Utama ID: '256:3153'
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
              onTap: _handleBack,
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
                    color: Color(0xFFFDF9F4),
                  ),
                ),
              ),
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            isEditMode ? "Edit Product" : "Add Product",
            style: const TextStyle(
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

      // --- MAIN SCROLLABLE CONTENT (Section 2 - 4) ---
      body: _isBootstrapping
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF012D1D)),
            )
          : SingleChildScrollView(
              physics: _isScrollEnabled ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ### [SECTION 2: FOTO BARANG (IMAGE UPLOAD GRID)]
                  _buildPhotoUploadSection(),
                  const SizedBox(height: 28),

                  // ### [SECTION 3: FORM INFORMASI BARANG]
                  _buildProductFormCard(),
                  const SizedBox(height: 32),

                  // ### [SECTION 4: LOKASI BARANG (MAP PREVIEW)]
                  _buildLocationMap(),
                  const SizedBox(height: 32),

                  // ### [SECTION 5: TAMBAH KE MARKETPLACE BUTTON]
                  _buildBottomActionButton(),

                  // Padding bottom extra agar seimbang di bawah layar
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // --- SECTION 2: FOTO BARANG UI ---
  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row Header: Title & Limit
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              "Foto Barang", // ID: '268:3247'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF012D1D),
              ),
            ),
            Text(
              "Maks 6 Foto", // ID: '268:3465'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7B5804), // Gold / Accent Color
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Otomatis disanitasi ke ${UploadImagePolicy.product.sizeLabelMb} MB agar storage hemat tapi tetap tajam di detail.',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Color(0xFF5C635E),
          ),
        ),
        const SizedBox(height: 16),

        // Baris 1: 2 Slot (index 0, 1)
        Row(
          children: [
            Expanded(child: _buildPhotoSlot(index: 0, isLarge: true)),
            const SizedBox(width: 16),
            Expanded(child: _buildPhotoSlot(index: 1, isLarge: true)),
          ],
        ),
        const SizedBox(height: 16),

        // Baris 2: 2 Slot (index 2, 3)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPhotoSlot(index: 2, isLarge: false)),
            const SizedBox(width: 16),
            Expanded(child: _buildPhotoSlot(index: 3, isLarge: false)),
          ],
        ),
        const SizedBox(height: 16),

        // Baris 3: 2 Slot (index 4, 5)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildPhotoSlot(index: 4, isLarge: false)),
            const SizedBox(width: 16),
            Expanded(child: _buildPhotoSlot(index: 5, isLarge: false)),
          ],
        ),
      ],
    );
  }

  Widget _buildPhotoSlot({required int index, required bool isLarge}) {
    final hasExisting = index < _existingPhotos.length;
    final hasNew = !hasExisting && (index - _existingPhotos.length) < _productPhotos.length;
    
    final existingUrl = hasExisting ? _existingPhotos[index] : null;
    final photo = hasNew ? _productPhotos[index - _existingPhotos.length] : null;
    
    final hasImage = existingUrl != null || photo != null;
    final bool displayAsLarge = isLarge || hasImage;
    
    final radius = BorderRadius.circular(40);
    final height = displayAsLarge ? 180.0 : 55.0;

    return GestureDetector(
      onTap: _isSubmitting ? null : _pickProductImages,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: displayAsLarge ? 0.04 : 0.03),
              blurRadius: displayAsLarge ? 15 : 8,
              offset: Offset(0, displayAsLarge ? 6 : 4),
            ),
          ],
        ),
        child: existingUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: radius,
                    child: Image(
                      image: _imageUploadService.buildImageProvider(existingUrl, targetWidth: displayAsLarge ? 360 : 110),
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: _isSubmitting
                          ? null
                          : () {
                              setState(() {
                                _existingPhotos.removeAt(index);
                              });
                            },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : photo == null
                ? _buildEmptyPhotoSlot(isLarge)
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: radius,
                        child: Image(
                          image: _imageUploadService.buildProcessedImageProvider(photo),
                          fit: BoxFit.cover,
                          filterQuality: FilterQuality.medium,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: _isSubmitting
                              ? null
                              : () => _removeProductPhoto(index - _existingPhotos.length),
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyPhotoSlot(bool isLarge) {
    if (!isLarge) {
      return const Center(
        child: Icon(Icons.add, color: Color(0xFF1B4332), size: 20),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3EE),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2DCD3), width: 0.5),
          ),
          child: const Center(
            child: Icon(
              Icons.camera_enhance_outlined,
              color: Color(0xFF1B4332),
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          "Unggah Foto",
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            "JPG sampai 2 MB\n1800px",
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 10,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C635E),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickProductImages() async {
    final remainingSlots =
        UploadImagePolicy.product.maxImages - (_existingPhotos.length + _productPhotos.length);
    if (remainingSlots <= 0) {
      _showSnack('Maksimal 6 foto barang.', true);
      return;
    }

    try {
      final sourceChoice = await _imageUploadService.chooseImageSource(context);
      if (sourceChoice == null) return;

      if (sourceChoice == ImageSourceChoice.camera) {
        final picked = await _imageUploadService.pickSingleImageFromSource(
          policy: UploadImagePolicy.product,
          source: ImageSource.camera,
        );
        if (picked == null || !mounted) return;
        setState(() {
          _productPhotos.add(picked);
        });
        return;
      }

      final picked = await _imageUploadService.pickMultipleImages(
        policy: UploadImagePolicy.product,
        remainingSlots: remainingSlots,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        _productPhotos.addAll(picked.take(remainingSlots));
      });
      if (picked.length < remainingSlots) {
        _showSnack(
          'Sebagian foto dilewati karena ukuran awal terlalu besar untuk disanitasi.',
          false,
        );
      }
    } catch (error) {
      _showSnack(safeImageError(error), true);
    }
  }

  void _removeProductPhoto(int index) {
    if (index < 0 || index >= _productPhotos.length) return;
    setState(() {
      _productPhotos.removeAt(index);
    });
  }

  // --- SECTION 3: PRODUCT FORM CARD ---
  Widget _buildProductFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Large outer card radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama Barang
          _buildLabel("Nama Barang"),
          const SizedBox(height: 8),
          _buildTextInput(
            hint: "Contoh: Kamera Canon Eos M100",
            controller: _nameController,
          ),
          const SizedBox(height: 20),

          // Deskripsi Barang
          _buildLabel("Deskripsi Barang"),
          const SizedBox(height: 8),
          _buildTextInput(
            hint: "Contoh: Kamera Profesional dengan",
            maxLines: 3,
            controller: _descriptionController,
          ),
          const SizedBox(height: 20),

          // Row: Kategori & Kondisi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Kategori"),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedCategoryId,
                      items: _categories
                          .map(
                            (cat) => DropdownMenuItem<String>(
                              value: (cat['id'] ?? '').toString(),
                              child: Text(
                                (cat['category'] ?? 'Kategori').toString(),
                              ),
                            ),
                          )
                          .toList(),
                      hint: 'Pilih kategori',
                      onChanged: (val) =>
                          setState(() => selectedCategoryId = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Kondisi"),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedKondisi,
                      items: kondisiList
                          .map(
                            (val) => DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            ),
                          )
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedKondisi = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row: Harga Sewa & Durasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Harga Sewa"),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      hint: "0",
                      controller: _priceController,
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Text(
                          "Rp. ",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Jam/Hari"),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedDurasi,
                      items: durasiList
                          .map(
                            (val) => DropdownMenuItem<String>(
                              value: val,
                              child: Text(val),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => selectedDurasi = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600, // SemiBold
        color: Color(0xFF012D1D),
      ),
    );
  }

  // Helper for Standard Text Inputs
  Widget _buildTextInput({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    Widget? prefix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _fieldFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorderColor),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF012D1D), // High contrast deep green
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _fieldHintColor,
          ),
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(
            minWidth: 0,
            minHeight: 0,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Helper for Dropdowns
  Widget _buildDropdown({
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: _fieldFillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _fieldBorderColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: hint == null
              ? null
              : Text(
                  hint,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: _fieldHintColor,
                  ),
                ),
          dropdownColor: _fieldFillColor,
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0xFF012D1D), // Standard icon color
            size: 24,
          ),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF012D1D), // Standard text color
          ),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }

  // --- SECTION 4: LOKASI BARANG ---
  Widget _buildLocationMap() {
    final selectedAddress = _addresses.cast<Map<String, dynamic>>().firstWhere(
      (address) => (address['id'] ?? '').toString() == _selectedAddressId,
      orElse: () => <String, dynamic>{},
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lokasi Barang", // ID: '268:3642'
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _useSavedAddress = true),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _useSavedAddress
                        ? const Color(0xFF012D1D)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF012D1D),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Alamat Tersimpan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _useSavedAddress
                            ? Colors.white
                            : const Color(0xFF012D1D),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _useSavedAddress = false),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: !_useSavedAddress
                        ? const Color(0xFF012D1D)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF012D1D),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Titik Baru',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: !_useSavedAddress
                            ? Colors.white
                            : const Color(0xFF012D1D),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (_useSavedAddress) ...[
          const SizedBox(height: 12),
          _buildDropdown(
            value: _selectedAddressId,
            items: _addresses
                .map(
                  (addr) => DropdownMenuItem<String>(
                    value: (addr['id'] ?? '').toString(),
                    child: Text(
                      _addressLabel(addr),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                )
                .toList(),
            hint: _addresses.isEmpty
                ? 'Belum ada alamat, pilih Titik Baru'
                : 'Pilih alamat',
            onChanged: _addresses.isEmpty
                ? (_) {}
                : (val) {
                    setState(() {
                      _selectedAddressId = val;
                      final found = _addresses.firstWhere(
                        (a) => (a['id'] ?? '').toString() == val,
                        orElse: () => <String, dynamic>{},
                      );
                      final coords = _extractLatLng(found['coordinat']);
                      if (coords != null) {
                        _itemLocation = coords;
                      }
                    });
                  },
          ),
          if (selectedAddress.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              (selectedAddress['fullAddress'] ?? '').toString(),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Color(0xFF5C635E),
              ),
            ),
          ],
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10), // Inner map container
          decoration: BoxDecoration(
            color: Colors.white, // ID: '268:3645'
            borderRadius: BorderRadius.circular(30), // Outer radius
            border: Border.all(
              color: const Color(
                0xFF1B4332,
              ).withValues(alpha: 0.5), // Outline 0.5px
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
            ), // ID: '268:3648' -> BorderRadius: 25px
            child: Listener(
              onPointerDown: (_) {
                if (!_useSavedAddress) {
                  setState(() => _isScrollEnabled = false);
                }
              },
              onPointerUp: (_) => setState(() => _isScrollEnabled = true),
              onPointerCancel: (_) => setState(() => _isScrollEnabled = true),
              child: ReusableMapCard(
                center: _itemLocation,
                zoom: 14,
                interactive: !_useSavedAddress,
                showCenterPin: true,
                overlayLabel: _useSavedAddress
                    ? 'Lokasi mengikuti alamat tersimpan'
                    : _customAddressLabel,
                onCenterChanged: _onMapCameraMove,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 5: BOTTOM ACTION BUTTON ---
  Widget _buildBottomActionButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submitProduct,
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF012D1D), // ID: '268:3651'
          borderRadius: BorderRadius.circular(180), // Pill shape
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF012D1D).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  isEditMode ? "Simpan Perubahan" : "Tambah ke Marketplace", // ID: '268:3652'
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700, // Bold
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _submitProduct() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final categoryId = (selectedCategoryId ?? '').trim();

    if (name.isEmpty || description.isEmpty || price <= 0) {
      _showSnack('Lengkapi nama, deskripsi, dan harga dulu.', true);
      return;
    }
    if (_existingPhotos.isEmpty && _productPhotos.isEmpty) {
      _showSnack('Tambahkan minimal 1 foto barang.', true);
      return;
    }
    if (categoryId.isEmpty) {
      _showSnack('Pilih kategori terlebih dahulu.', true);
      return;
    }
    if (_useSavedAddress &&
        (_selectedAddressId == null || _selectedAddressId!.isEmpty)) {
      _showSnack('Pilih alamat tersimpan atau gunakan titik baru.', true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _authSessionService.getValidIdToken(forceRefresh: true);
      if (token == null || token.isEmpty) {
        _showSnack('Token login tidak ditemukan. Silakan login ulang.', true);
        return;
      }

      final payload = {
        'name': name,
        'description': description,
        'pricePerHour': price,
        'categoryId': categoryId,
        'conditionLabel': selectedKondisi,
        'durationUnit': selectedDurasi,
        'latitude': _itemLocation.latitude,
        'longitude': _itemLocation.longitude,
        'addressSource': _useSavedAddress ? 'saved' : 'new',
      };

      // Tetap simpan dummy payload sebagai backup demo.
      await prefs.setString('pending_add_product_payload', jsonEncode(payload));

      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      String normalizeAuthError(String fallback) {
        if (fallback.toLowerCase().contains('token')) {
          return 'Sesi login sudah tidak valid. Silakan login ulang.';
        }
        return fallback;
      }

      // Resolve addressId: reuse saved or create a new one.
      String addressId = (_selectedAddressId ?? '').trim();
      if (!_useSavedAddress) {
        final fullAddress = (_customAddressLabel == 'Geser map untuk set titik barang' || _customAddressLabel.isEmpty)
            ? 'Pinned: ${_itemLocation.latitude.toStringAsFixed(6)}, ${_itemLocation.longitude.toStringAsFixed(6)}'
            : _customAddressLabel;
        final addressResp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/addresses'),
          headers: headers,
          body: jsonEncode({
            'label': 'Lokasi Barang',
            'fullAddress': fullAddress,
            'latitude': _itemLocation.latitude,
            'longitude': _itemLocation.longitude,
            'isDefault': false,
          }),
        );
        final addressBody =
            jsonDecode(addressResp.body) as Map<String, dynamic>;
        if (addressResp.statusCode != 200 || addressBody['success'] != true) {
          _showSnack(
            normalizeAuthError(
              addressBody['error']?['message']?.toString() ??
                  'Gagal menyimpan alamat barang.',
            ),
            true,
          );
          return;
        }
        addressId = (addressBody['data']?['id'] ?? '').toString();
      }
      if (addressId.isEmpty) {
        _showSnack('Address ID tidak ditemukan.', true);
        return;
      }

      if (isEditMode) {
        final itemId = widget.editItem!.id;
        final itemResp = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/items/$itemId'),
          headers: headers,
          body: jsonEncode({
            'categoryId': categoryId,
            'name': name,
            'description': description,
            'price': price,
            'priceUnit': selectedDurasi,
            'estimatedValue': selectedDurasi == 'Jam' ? price * 24 : (selectedDurasi == 'Minggu' ? price / 7 : price),
            'condition': _mapConditionToApi(selectedKondisi),
            'addressId': addressId,
            'photos': _existingPhotos,
          }),
        );
        final itemBody = jsonDecode(itemResp.body) as Map<String, dynamic>;
        if (itemResp.statusCode != 200 || itemBody['success'] != true) {
          _showSnack(
            normalizeAuthError(
              itemBody['error']?['message']?.toString() ?? 'Gagal menyimpan perubahan.',
            ),
            true,
          );
          return;
        }

        // Upload any new photos
        for (var i = 0; i < _productPhotos.length; i++) {
          final photo = _productPhotos[i];
          final photoUrl = await _imageUploadService.uploadProcessedImage(
            processed: photo,
            storagePath: _imageUploadService.buildItemPhotoStoragePath(
              itemId: itemId,
              index: _existingPhotos.length + i + 1,
            ),
          );

          final photoResp = await http.post(
            Uri.parse('${ApiConfig.baseUrl}/items/$itemId/photos'),
            headers: headers,
            body: jsonEncode({'photoUrl': photoUrl}),
          );
          final photoBody = jsonDecode(photoResp.body) as Map<String, dynamic>;
          if (photoResp.statusCode != 200 || photoBody['success'] != true) {
            _showSnack('Perubahan disimpan, tapi upload foto baru gagal.', true);
            return;
          }
        }

        if (!mounted) return;
        showAppSuccessSnack(context, 'Barang berhasil diperbarui!');
        Navigator.pop(context, true);
        return;
      }

      // 3) Create item real ke backend functions
      final itemResp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/items'),
        headers: headers,
        body: jsonEncode({
          'categoryId': categoryId,
          'name': name,
          'description': description,
          'price': price,
          'priceUnit': selectedDurasi,
          'estimatedValue': selectedDurasi == 'Jam' ? price * 24 : (selectedDurasi == 'Minggu' ? price / 7 : price),
          'condition': _mapConditionToApi(selectedKondisi),
          'addressId': addressId,
        }),
      );
      final itemBody = jsonDecode(itemResp.body) as Map<String, dynamic>;
      if (itemResp.statusCode != 200 || itemBody['success'] != true) {
        _showSnack(
          normalizeAuthError(
            itemBody['error']?['message']?.toString() ??
                'Gagal menambahkan barang.',
          ),
          true,
        );
        return;
      }

      final itemId = (itemBody['data']?['id'] ?? '').toString();
      if (itemId.isEmpty) {
        _showSnack('ID barang tidak ditemukan setelah item dibuat.', true);
        return;
      }

      for (var i = 0; i < _productPhotos.length; i++) {
        final photo = _productPhotos[i];
        final photoUrl = await _imageUploadService.uploadProcessedImage(
          processed: photo,
          storagePath: _imageUploadService.buildItemPhotoStoragePath(
            itemId: itemId,
            index: i + 1,
          ),
        );

        final photoResp = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/items/$itemId/photos'),
          headers: headers,
          body: jsonEncode({'photoUrl': photoUrl}),
        );
        final photoBody = jsonDecode(photoResp.body) as Map<String, dynamic>;
        if (photoResp.statusCode != 200 || photoBody['success'] != true) {
          _showSnack(
            normalizeAuthError(
              photoBody['error']?['message']?.toString() ??
                  'Barang berhasil dibuat, tapi upload foto gagal.',
            ),
            true,
          );
          return;
        }
      }

      if (!_useSavedAddress) {
        _bootstrapFormData();
      }
      
      // Save item to local SharedPreferences for immediate UI update in My Items and Profile View
      try {
        final prefs = await SharedPreferences.getInstance();
        final localItemsStr = prefs.getString('local_user_items') ?? '[]';
        final List<dynamic> localItems = jsonDecode(localItemsStr);
        
        // Find category name for display
        final categoryName = _categories.firstWhere(
          (cat) => (cat['id'] ?? '').toString() == categoryId,
          orElse: () => {'category': 'Lainnya'}
        )['category'];

        localItems.insert(0, {
          'id': itemId,
          'name': name,
          'price': 'Rp.${price.toInt().toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (match) => ".")}/${selectedDurasi.toLowerCase()}',
          'category': categoryName,
          'rating': '0.0(0)', // Default for new item
          'image': _productPhotos.isNotEmpty ? _productPhotos.first.localPath : (_existingPhotos.isNotEmpty ? _existingPhotos.first : ''),
          'isLocalAsset': _productPhotos.isNotEmpty, // Because it's an XFile path
          'more_options': true,
        });
        
        await prefs.setString('local_user_items', jsonEncode(localItems));
      } catch (e) {
        debugPrint('Failed to save to local_user_items: $e');
      }

      if (!mounted) return;
      AddItemSuccessModal.show(context);

      setState(() {
        _productPhotos.clear();
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
      });
    } catch (_) {
      _showSnack('Gagal menyiapkan payload produk.', true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _mapConditionToApi(String local) {
    final normalized = local.toLowerCase();
    if (normalized.contains('baru')) return 'new';
    if (normalized.contains('sangat')) return 'like-new';
    if (normalized == 'baik') return 'fair';
    return 'poor';
  }

  void _showSnack(String message, bool isError) {
    if (isError) {
      showAppErrorSnack(context, message);
      return;
    }
    showAppSuccessSnack(context, message);
  }
}
