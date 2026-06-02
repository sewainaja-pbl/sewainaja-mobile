import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'address_service.dart';
import 'default_address_setup_screen.dart';
import 'map_common_widgets.dart';
import 'api_config.dart';
import 'app_feedback.dart';
import 'auth_session_service.dart';
import 'image_upload_service.dart';
import 'profile_sync_service.dart';
import 'upload_image_policy.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const EditProfileScreen({super.key, this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const LatLng _fallbackMapCenter = LatLng(-6.966667, 110.416664);
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  final AddressService _addressService = const AddressService();
  String _defaultLocation = "";
  LatLng _profileMapCenter = _fallbackMapCenter;
  final ImageUploadService _imageUploadService = ImageUploadService();
  final AuthSessionService _authSessionService = const AuthSessionService();
  final ProfileSyncService _profileSyncService = const ProfileSyncService();
  String _profilePhotoUrl = '';
  ProcessedImageFile? _pendingProfilePhoto;
  bool _isSaving = false;
  Timer? _debounceTimer;
  bool _isScrollEnabled = true;

  void _handleBack() {
    final didPop = Navigator.of(context).maybePop();
    didPop.then((popped) {
      if (!popped && widget.onBack != null) {
        widget.onBack!();
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _nameFocusNode.addListener(_refreshFieldState);
    _phoneFocusNode.addListener(_refreshFieldState);
    _loadUserData();
  }

  void _refreshFieldState() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _nameFocusNode.removeListener(_refreshFieldState);
    _phoneFocusNode.removeListener(_refreshFieldState);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final cached = await _profileSyncService.readCachedProfile();
      if (!mounted) return;
      setState(() {
        _nameController.text = cached.displayName;
        _emailController.text = cached.displayEmail;
        _phoneController.text = cached.displayPhone;
        _profilePhotoUrl = cached.profilePhotoUrl;
      });
      final prefs = await SharedPreferences.getInstance();
      final defaultLocation = prefs.getString('user_default_location');
      final defaultLat = prefs.getDouble('user_default_lat');
      final defaultLng = prefs.getDouble('user_default_lng');
      if (defaultLocation != null && defaultLocation.trim().isNotEmpty && mounted) {
        setState(() {
          _defaultLocation = defaultLocation;
        });
      }
      if (defaultLat != null && defaultLng != null && mounted) {
        setState(() {
          _profileMapCenter = LatLng(defaultLat, defaultLng);
        });
      }
      final synced = await _profileSyncService.syncProfileFromApi();
      if (synced == null || !mounted) return;
      setState(() {
        _nameController.text = synced.displayName;
        _emailController.text = synced.displayEmail;
        _phoneController.text = synced.displayPhone;
        _profilePhotoUrl = synced.profilePhotoUrl;
      });
      await _loadDefaultAddressFromApi();
    } catch (_) {}
  }

  Future<void> _loadDefaultAddressFromApi() async {
    try {
      final address = await _addressService.fetchDefaultAddress();
      if (address == null || !mounted) return;
      final resolvedLabel = address.fullAddress.trim().isNotEmpty
          ? address.fullAddress.trim()
          : address.label.trim();
      final lat = address.latitude;
      final lng = address.longitude;
      final prefs = await SharedPreferences.getInstance();
      if (resolvedLabel.isNotEmpty) {
        await prefs.setString('user_default_location', resolvedLabel);
      }
      if (lat != null && lng != null) {
        await prefs.setDouble('user_default_lat', lat);
        await prefs.setDouble('user_default_lng', lng);
      }
      if (!mounted) return;
      setState(() {
        if (resolvedLabel.isNotEmpty) {
          _defaultLocation = resolvedLabel;
        }
        if (lat != null && lng != null) {
          _profileMapCenter = LatLng(lat, lng);
        }
      });
    } catch (_) {
      // Keep cached location when address API is temporarily unavailable.
    }
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final sourceChoice = await _imageUploadService.chooseImageSource(context);
      if (sourceChoice == null) return;
      final picked = await _imageUploadService.pickSingleImageFromSource(
        policy: UploadImagePolicy.profile,
        source: sourceChoice == ImageSourceChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _pendingProfilePhoto = picked;
      });
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnack(context, safeImageError(error));
    }
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final trimmedName = _nameController.text.trim();
    final trimmedPhone = _phoneController.text.trim();
    if (trimmedName.isEmpty) {
      showAppErrorSnack(context, 'Nama tidak boleh kosong.');
      return;
    }
    if (trimmedPhone.isEmpty) {
      showAppErrorSnack(context, 'Nomor telepon tidak boleh kosong.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _authSessionService.getValidIdToken(forceRefresh: true) ?? '';
      final userId = prefs.getString('user_id')?.trim() ?? '';
      if (token.isEmpty) {
        if (!mounted) return;
        showAppErrorSnack(context, 'Sesi login sudah tidak valid. Silakan login ulang.');
        return;
      }
      var resolvedPhotoUrl = _profilePhotoUrl;

      if (_pendingProfilePhoto != null) {
        if (userId.isEmpty) {
          if (!mounted) return;
          showAppErrorSnack(context, 'User ID tidak ditemukan. Silakan login ulang.');
          return;
        }
        resolvedPhotoUrl = await _imageUploadService.uploadProcessedImage(
          processed: _pendingProfilePhoto!,
          storagePath: _imageUploadService.buildUserAvatarStoragePath(userId),
        );
      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': trimmedName,
          'phone': trimmedPhone,
          'profilePhotoUrl': resolvedPhotoUrl,
        }),
      );
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode != 200 || body['success'] != true) {
        if (!mounted) return;
        final message = body['error']?['message']?.toString() ?? 'Gagal memperbarui profil.';
        showAppErrorSnack(
          context,
          message.toLowerCase().contains('token')
              ? 'Sesi login sudah tidak valid. Silakan login ulang.'
              : message,
        );
        return;
      }

      final responseData = body['data'];
      final updatedProfile = responseData is Map<String, dynamic>
          ? CachedUserProfile.fromJson(responseData)
          : CachedUserProfile(
              name: trimmedName,
              email: _emailController.text.trim(),
              phone: trimmedPhone,
              profilePhotoUrl: resolvedPhotoUrl,
              status: '',
            );
      await _profileSyncService.saveProfileToCache(updatedProfile, notify: true);
      if (!mounted) return;
      setState(() {
        _nameController.text = updatedProfile.displayName;
        _emailController.text = updatedProfile.displayEmail;
        _phoneController.text = updatedProfile.displayPhone;
        _profilePhotoUrl = updatedProfile.profilePhotoUrl;
        _pendingProfilePhoto = null;
      });
      if (!mounted) return;
      showAppSuccessSnack(context, 'Profil berhasil diperbarui.');
      if (widget.onBack != null) {
        widget.onBack!();
      } else {
        Navigator.maybePop(context);
      }
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnack(context, safeImageError(error));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _editDefaultAddress() async {
    if (_isSaving) return;
    final result = await Navigator.push<DefaultAddressResult>(
      context,
      MaterialPageRoute(
        builder: (_) => DefaultAddressSetupScreen(
          returnSelectionOnSave: true,
          initialCenter: _profileMapCenter,
          initialLabel: _defaultLocation,
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      _defaultLocation = result.label;
      _profileMapCenter = result.center;
    });
  }

  void _onMapCameraMove(LatLng newCenter) {
    setState(() {
      _profileMapCenter = newCenter;
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
          'lat': _profileMapCenter.latitude.toString(),
          'lon': _profileMapCenter.longitude.toString(),
          'format': 'jsonv2',
          'zoom': '16',
        },
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'sewainaja-mobile/1.0 (profile-map)'},
      );
      if (response.statusCode != 200) return;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final raw = (body['display_name'] ?? '').toString().trim();
      if (raw.isEmpty) return;
      if (!mounted) return;
      
      final shortAddr = _shortAddress(raw);
      setState(() {
        _defaultLocation = shortAddr;
      });
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_default_location', shortAddr);
      await prefs.setDouble('user_default_lat', _profileMapCenter.latitude);
      await prefs.setDouble('user_default_lng', _profileMapCenter.longitude);
      
      final token = prefs.getString('token');
      if (token != null && token.isNotEmpty) {
        try {
          await _addressService.upsertDefaultAddress(
            label: 'Alamat Utama',
            fullAddress: shortAddr,
            latitude: _profileMapCenter.latitude,
            longitude: _profileMapCenter.longitude,
          );
        } catch (_) {}
      }
      
      ProfileSyncService.profileRevision.value++;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Color_Background
      // --- SECTION 1: APPBAR / HEADER ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        centerTitle: true,
        leadingWidth: 76,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24, top: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: _handleBack,
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF012D1D),
                size: 28,
              ),
            ),
          ),
        ),
        title: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            "Edit Profile",
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

      // --- MAIN BODY ---
      body: SingleChildScrollView(
        physics: _isScrollEnabled ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40), // Spacing for scroll
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ### [SECTION 2: AVATAR EDIT SECTION] ###
            _buildAvatarSection(),

            const SizedBox(height: 32),

            // ### [SECTION 3: PROFILE FORM CARD] ###
            _buildProfileFormCard(),
          ],
        ),
      ),

      // --- SECTION 4: BOTTOM ACTION BAR (FIXED) ---
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // Widget for Section 2: Avatar
  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Circular Avatar (ID: '536:1925')
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(
                  0xFF1B4332,
                ).withValues(alpha: 0.2), // Subtle border
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(70),
              child: Image(
                image: _resolvedProfileImage(),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Image.asset(
                  'assets/images/profile_user.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Edit Badge Overlay (ID: '536:1932')
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isSaving ? null : _pickProfilePhoto,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white, // ID: '536:1931' Background Kotak
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.edit_rounded, // ID: '536:1929' Edit Icon
                  color: Color(0xFF012D1D),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Section 3: Form Card
  Widget _buildProfileFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // ID: '536:1933' Background
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 3A. NAMA
          _buildFormRow(
            label: "Nama", // ID: '536:1945'
            controller: _nameController,
            focusNode: _nameFocusNode,
            helperText: 'Tap untuk ubah nama profil.',
          ),
          const SizedBox(height: 16),

          // 3B. EMAIL
          _buildFormRow(
            label: "Email", // ID: '536:1946'
            controller: _emailController,
            readOnly: true,
            helperText: 'Email belum bisa diubah dari aplikasi.',
          ),
          const SizedBox(height: 16),

          // 3C. NO TELPON
          _buildFormRow(
            label: "No. Telpon", // ID: '536:1948'
            controller: _phoneController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.phone,
            helperText: 'Tap untuk ubah nomor telepon.',
          ),
          const SizedBox(height: 16),

          // 3D. ALAMAT & MAP
          _buildAddressRow(),
        ],
      ),
    );
  }

  // Helper to build standard Row (Nama, Email, Telpon)
  Widget _buildFormRow({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    String? helperText,
  }) {
    final accentColor = readOnly
        ? const Color(0xFF717973)
        : const Color(0xFF012D1D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE1), // Color_Row_Bg: Soft Beige
        borderRadius: BorderRadius.circular(11),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: readOnly
            ? null
            : () {
                focusNode?.requestFocus();
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1B4332),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: readOnly
                        ? const Color(0xFFE4E0D5)
                        : const Color(0xFFE9F2ED),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        readOnly
                            ? Icons.lock_outline_rounded
                            : Icons.edit_outlined,
                        size: 14,
                        color: accentColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        readOnly ? 'Read only' : 'Tap untuk ubah',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: readOnly ? 0.52 : 0.96),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: readOnly
                      ? const Color(0xFFD8D0C3)
                      : (focusNode?.hasFocus ?? false)
                            ? const Color(0xFF2F6743)
                            : const Color(0xFFC9D5CE),
                  width: (focusNode?.hasFocus ?? false) ? 1.4 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      readOnly: readOnly,
                      keyboardType: keyboardType,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: readOnly
                            ? const Color(0xFF717973)
                            : const Color(0xFF1C1C19),
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: InputBorder.none,
                        hintText: label,
                        hintStyle: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          color: Color(0xFF9AA29D),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    readOnly
                        ? Icons.info_outline_rounded
                        : Icons.chevron_right_rounded,
                    size: 18,
                    color: accentColor.withValues(alpha: 0.8),
                  ),
                ],
              ),
            ),
            if (helperText != null) ...[
              const SizedBox(height: 8),
              Text(
                helperText,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF717973),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper to build Address Row (includes Map)
  Widget _buildAddressRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE1), // Soft Beige
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Alamat", // ID: '536:1950'
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B4332),
                ),
              ),
              Expanded(
                child: Text(
                  _defaultLocation, // ID: '536:2186'
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _editDefaultAddress,
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC9D5CE)),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.edit_location_alt_rounded,
                    size: 18,
                    color: Color(0xFF012D1D),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap untuk ubah alamat utama',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF012D1D),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Map Image Component (ID: '536:2196')
          Container(
            height: 120, // Specific height to show map clearly
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(
                  0xFF012D1D,
                ).withValues(alpha: 0.5), // Outline: #012D1D 0.5px equivalent
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Listener(
                onPointerDown: (_) => setState(() => _isScrollEnabled = false),
                onPointerUp: (_) => setState(() => _isScrollEnabled = true),
                onPointerCancel: (_) => setState(() => _isScrollEnabled = true),
                child: ReusableMapCard(
                  center: _profileMapCenter,
                  zoom: 13,
                  interactive: true,
                  showCenterPin: true,
                  onCenterChanged: _onMapCameraMove,
                  overlayLabel: _defaultLocation,
                  height: 120,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Section 4: Bottom Action Bar
  Widget _buildBottomActionBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: 20,
          top: 10,
        ),
        child: GestureDetector(
          onTap: _isSaving ? null : _saveProfile,
          child: Container(
            height: 54, // Modern standard button height
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332), // Color_Primary
              borderRadius: BorderRadius.circular(25), // Pill Shape
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4332).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Konfirmasi", // ID: '536:2156'
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600, // SemiBold
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  ImageProvider _resolvedProfileImage() {
    if (_pendingProfilePhoto != null) {
      return _imageUploadService.buildProcessedImageProvider(_pendingProfilePhoto!);
    }
    if (_profilePhotoUrl.trim().isNotEmpty) {
      return _imageUploadService.buildImageProvider(_profilePhotoUrl);
    }
    return const AssetImage('assets/images/profile_user.png');
  }
}
