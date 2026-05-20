import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_common_widgets.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';
import 'app_feedback.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddProductScreen({super.key, this.onBack});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  String? selectedCategoryId;
  String selectedKondisi = "Sangat Baik";
  String selectedDurasi = "Hari";
  LatLng _itemLocation = const LatLng(-6.966667, 110.416664);
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  bool _useSavedAddress = true;
  bool _isBootstrapping = true;
  bool _isSubmitting = false;
  List<Map<String, dynamic>> _categories = const [];
  List<Map<String, dynamic>> _addresses = const [];
  String? _selectedAddressId;

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
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
        http.get(Uri.parse('${ApiConfig.baseUrl}/categories'), headers: headers),
        http.get(Uri.parse('${ApiConfig.baseUrl}/addresses'), headers: headers),
      ]);

      final categoryResp = responses[0];
      final addressResp = responses[1];
      final categoryBody = jsonDecode(categoryResp.body) as Map<String, dynamic>;
      final addressBody = jsonDecode(addressResp.body) as Map<String, dynamic>;

      if (categoryResp.statusCode != 200 || categoryBody['success'] != true) {
        _showSnack('Gagal ambil data kategori.', true);
      }

      if (addressResp.statusCode != 200 || addressBody['success'] != true) {
        _showSnack('Gagal ambil data alamat.', true);
      }

      final categories =
          (categoryBody['data'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
      final addresses =
          (addressBody['data'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();

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
        _isBootstrapping = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isBootstrapping = false);
      _showSnack('Gagal mengambil data awal form.', true);
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

  String _addressLabel(Map<String, dynamic> address) {
    final label = (address['label'] ?? '').toString().trim();
    final full = (address['fullAddress'] ?? '').toString().trim();
    if (label.isEmpty) return full;
    if (full.isEmpty) return label;
    return '$label • $full';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        titleSpacing: 24,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: _handleBack,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF012D1D), // Circle Background: #012D1D
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
              const Spacer(),
              // Title: "Add Product"
              const Text(
                "Add Product",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w700, // SemiBold / Bold in screen spec
                  color: Color(0xFF012D1D),
                ),
              ),
              const Spacer(),
              // Hidden dummy to keep title perfectly centered
              const SizedBox(width: 42),
            ],
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
        physics: const BouncingScrollPhysics(),
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
              "Maks 5 Foto", // ID: '268:3465'
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

        // Baris 1: 2 Slot Besar
        Row(
          children: [
            Expanded(child: _buildBigUploadSlot()),
            const SizedBox(width: 16),
            Expanded(child: _buildBigUploadSlot()),
          ],
        ),
        const SizedBox(height: 16),

        // Baris 2: 3 Slot Kecil
        Row(
          children: [
            Expanded(child: _buildSmallUploadSlot()),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallUploadSlot()),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallUploadSlot()),
          ],
        ),
      ],
    );
  }

  // Helper widget for Big Photo Slot
  Widget _buildBigUploadSlot() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Radius 40px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circle Background for Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EE), // Soft Grey/Cream Variant
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2DCD3), width: 0.5),
            ),
            child: const Center(
              child: Icon(
                Icons.camera_enhance_outlined,
                color: Color(0xFF1B4332), // Camera Icon Color
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Texts
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
          const Text(
            "JPG, PNG (Max 5MB)",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C635E), // Subtitle color
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for Small Photo Slot
  Widget _buildSmallUploadSlot() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Radius 40px (Pill)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.add, color: Color(0xFF1B4332), size: 20),
      ),
    );
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
                              child: Text((cat['category'] ?? 'Kategori').toString()),
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
        color: const Color(0xFFD9D9D9), // Updated to #D9D9D9
        borderRadius: BorderRadius.circular(12),
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
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF717973), // Standard muted gray hint
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
        color: const Color(0xFFD9D9D9), // Updated to #D9D9D9
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF717973),
                  ),
                ),
          dropdownColor: const Color(0xFFD9D9D9), // Matches dropdown bg
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
                    color: _useSavedAddress ? const Color(0xFF012D1D) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF012D1D), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'Alamat Tersimpan',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: _useSavedAddress ? Colors.white : const Color(0xFF012D1D),
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
                    color: !_useSavedAddress ? const Color(0xFF012D1D) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF012D1D), width: 1),
                  ),
                  child: Center(
                    child: Text(
                      'Titik Baru',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: !_useSavedAddress ? Colors.white : const Color(0xFF012D1D),
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
            child: ReusableMapCard(
              center: _itemLocation,
              zoom: 14,
              interactive: !_useSavedAddress,
              showCenterPin: true,
              overlayLabel: _useSavedAddress
                  ? 'Lokasi mengikuti alamat tersimpan'
                  : 'Geser map untuk set titik barang',
              onCenterChanged: (center) {
                if (_useSavedAddress) return;
                setState(() {
                  _itemLocation = center;
                });
              },
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
              : const Text(
                  "Tambah ke Marketplace", // ID: '268:3652'
                  style: TextStyle(
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
    if (categoryId.isEmpty) {
      _showSnack('Pilih kategori terlebih dahulu.', true);
      return;
    }
    if (_useSavedAddress && (_selectedAddressId == null || _selectedAddressId!.isEmpty)) {
      _showSnack('Pilih alamat tersimpan atau gunakan titik baru.', true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
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

      // Resolve addressId: reuse saved or create a new one.
      String addressId = (_selectedAddressId ?? '').trim();
      if (!_useSavedAddress) {
        final fullAddress =
            'Pinned: ${_itemLocation.latitude.toStringAsFixed(6)}, ${_itemLocation.longitude.toStringAsFixed(6)}';
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
        final addressBody = jsonDecode(addressResp.body) as Map<String, dynamic>;
        if (addressResp.statusCode != 200 || addressBody['success'] != true) {
          _showSnack(
            addressBody['error']?['message']?.toString() ??
                'Gagal menyimpan alamat barang.',
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

      // 3) Create item real ke backend functions
      final itemResp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/items'),
        headers: headers,
        body: jsonEncode({
          'categoryId': categoryId,
          'name': name,
          'description': description,
          'pricePerHour': price,
          'estimatedValue': price * 24,
          'condition': _mapConditionToApi(selectedKondisi),
          'addressId': addressId,
        }),
      );
      final itemBody = jsonDecode(itemResp.body) as Map<String, dynamic>;
      if (itemResp.statusCode != 200 || itemBody['success'] != true) {
        _showSnack(
          itemBody['error']?['message']?.toString() ?? 'Gagal menambahkan barang.',
          true,
        );
        return;
      }

      _showSnack('Barang berhasil ditambahkan ke marketplace.', false);
      if (!_useSavedAddress) {
        _bootstrapFormData();
      }
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
