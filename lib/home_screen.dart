
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'address_service.dart';
import 'data/models/item_model.dart';
import 'data/repositories/item_repository.dart';
import 'image_upload_service.dart';
import 'item_detail_screen.dart';
import 'map_common_widgets.dart';
import 'map_explore_screen.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'new_arrivals_screen.dart';
import 'notification_screen.dart';
import 'search_screen.dart';
import 'default_address_setup_screen.dart';
import 'profile_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final ValueChanged<bool>? onSearchActiveChanged;
  final VoidCallback? onProfileRequested;
  const HomeScreen({
    super.key,
    this.onSearchActiveChanged,
    this.onProfileRequested,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  static const LatLng _fallbackCenter = LatLng(-6.966667, 110.416664);
  final AddressService _addressService = const AddressService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ItemRepository _itemRepo = ItemRepository();

  String selectedCategory = 'All';
  String _defaultLocationLabel = '';
  String _userName = '';
  String _profilePhotoUrl = '';
  LatLng _mapCenter = _fallbackCenter;

  // Kategori dari Firestore + "All" selalu ada di depan
  List<String> _firestoreCategories = [];

  // Search state shared with SearchScreen
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  final GlobalKey<SearchSheetState> _searchSheetKey =
      GlobalKey<SearchSheetState>();

  // Animation for home sheet sliding down when search opens
  late final AnimationController _homeSheetAnim;
  late final Animation<Offset> _homeSheetSlide;
  ScrollController? _activeScrollController;
  final GlobalKey _trustedSectionKey = GlobalKey();
  bool _isMapCardPressed = false;

  /// Kategori yang ditampilkan di filter chip: "All" + kategori dari Firestore.
  List<String> get categories {
    if (_firestoreCategories.isEmpty) {
      // Fallback lokal saat Firestore belum load
      return [
        'All',
        'Tech',
        'Power Tools',
        'Outfit',
        'Camp Tools',
        'Sports',
        'Cook',
      ];
    }
    return ['All', ..._firestoreCategories];
  }

  @override
  void initState() {
    super.initState();
    _loadDefaultLocationLabel();
    _loadCategories();

    // Home sheet slides UP (out) when search opens, slides DOWN back in when closing
    _homeSheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 0,
    );
    _homeSheetSlide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1), // slides UP off screen
    ).animate(CurvedAnimation(parent: _homeSheetAnim, curve: Curves.easeInCubic));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _homeSheetAnim.dispose();
    super.dispose();
  }

  /// Load kategori dari Firestore collection `item_categories`.
  Future<void> _loadCategories() async {
    try {
      final names = await _itemRepo.fetchCategoryNames();
      if (!mounted) return;
      setState(() {
        _firestoreCategories = names;
        // Reset ke 'All' jika kategori yang dipilih tidak ada lagi
        if (!categories.contains(selectedCategory)) {
          selectedCategory = 'All';
        }
      });
    } catch (_) {
      // Keep fallback categories on error
    }
  }

  void _openSearch() {
    setState(() => _isSearchActive = true);
    widget.onSearchActiveChanged?.call(true);
    _homeSheetAnim.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    // 1. Search sheet slides DOWN out of view
    _searchSheetKey.currentState?.closeAsync().then((_) {
      // 2. Home sheet slides DOWN back into view from above
      _searchController.clear();
      _homeSheetAnim.reverse().then((_) {
        if (mounted) {
          setState(() => _isSearchActive = false);
          widget.onSearchActiveChanged?.call(false);
        }
      });
    });
  }

  void _openSettings() {
    if (widget.onProfileRequested != null) {
      widget.onProfileRequested!();
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileSettingsScreen(),
      ),
    ).then((_) {
      _loadDefaultLocationLabel();
    });
  }

  Future<void> _openDefaultLocation() async {
    final result = await Navigator.push<DefaultAddressResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const DefaultAddressSetupScreen(returnSelectionOnSave: true),
      ),
    );

    if (!mounted || result == null) return;
    setState(() {
      _defaultLocationLabel = result.label;
      _mapCenter = result.center;
    });
  }

  void _scrollToProducts() {
    setState(() {
      selectedCategory = 'All';
    });
    if (_activeScrollController == null) return;
    try {
      final context = _trustedSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _activeScrollController!.animateTo(
          380,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    } catch (_) {
      _activeScrollController!.animateTo(
        380,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _loadDefaultLocationLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString('user_default_location')?.trim();
    final name = prefs.getString('user_name')?.trim();
    final profilePhotoUrl = prefs.getString('user_profile_photo_url')?.trim();
    final lat = prefs.getDouble('user_default_lat');
    final lng = prefs.getDouble('user_default_lng');
    if (!mounted) return;
    setState(() {
      if (label != null && label.isNotEmpty) {
        _defaultLocationLabel = label;
      }
      if (name != null && name.isNotEmpty) {
        _userName = name;
      }
      if (profilePhotoUrl != null && profilePhotoUrl.isNotEmpty) {
        _profilePhotoUrl = profilePhotoUrl;
      }
      if (lat != null && lng != null) {
        _mapCenter = LatLng(lat, lng);
      }
    });
    _syncDefaultLocationFromApi();
  }

  Future<void> _syncDefaultLocationFromApi() async {
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
          _defaultLocationLabel = resolvedLabel;
        }
        if (lat != null && lng != null) {
          _mapCenter = LatLng(lat, lng);
        }
      });
    } catch (_) {
      // Keep local fallback if token is unavailable or request fails.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF012D1D),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // =============================================================
          // ### [LAYER 1: BACKGROUND / FIXED GREEN HEADER]
          // =============================================================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 24),
                    _buildSearchBar(),
                  ],
                ),
              ),
            ),
          ),

          // =============================================================
          // ### [LAYER 2: HOME SHEET — slides down when search opens]
          // =============================================================
          SlideTransition(
            position: _homeSheetSlide,
            child: DraggableScrollableSheet(
              initialChildSize: 0.76,
              minChildSize: 0.76,
              maxChildSize: 1.0,
              snap: true,
              builder: (context, scrollController) {
                _activeScrollController = scrollController;
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8EF),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 5,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD6C7A1).withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(top: 8)),
                      SliverToBoxAdapter(child: _buildPromoBanner()),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      SliverToBoxAdapter(child: _buildLocationPreview()),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      SliverToBoxAdapter(
                        child: _buildSectionHeader(
                          "New Arrivals",
                          onSeeMoreTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NewArrivalsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(child: _buildNewArrivals()),
                      const SliverToBoxAdapter(child: SizedBox(height: 28)),
                      SliverToBoxAdapter(
                        key: _trustedSectionKey,
                        child: _buildSectionHeader(
                          "Most Trusted Nearby",
                          showSeeMore: false,
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      SliverToBoxAdapter(child: _buildCategoryFilter()),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      _buildTrustedNearbySliver(),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                    ],
                  ),
                );
              },
            ),
          ),

          // =============================================================
          // ### [LAYER 3: SEARCH SHEET — slides up when search opens]
          // =============================================================
          if (_isSearchActive)
            SearchSheet(
              key: _searchSheetKey,
              controller: _searchController,
              focusNode: _searchFocusNode,
              onClose: _closeSearch,
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS FOR LAYER 1 (FIXED BACKGROUND)
  // ---------------------------------------------------------------------------

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: _openSettings,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                image: DecorationImage(
                  image: _profilePhotoUrl.trim().isEmpty
                      ? const AssetImage('assets/images/profile_user.png')
                      : _imageUploadService.buildImageProvider(_profilePhotoUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: _openSettings,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    _userName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFDF9F4),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                GestureDetector(
                  onTap: _openDefaultLocation,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 12,
                        color: Color(0xFFFDF9F4),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _defaultLocationLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: Color(0xFFFDF9F4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onTap: () {
            if (!_isSearchActive) _openSearch();
          },
          onChanged: (_) {
            // Trigger rebuild in SearchSheet via shared controller listener
            if (!_isSearchActive) _openSearch();
          },
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF012D1D),
            ),
            suffixIcon: _isSearchActive
                ? GestureDetector(
                    onTap: _closeSearch,
                    child: const Icon(
                      Icons.close_rounded,
                      color: Color(0xFF012D1D),
                      size: 20,
                    ),
                  )
                : null,
            hintText: "Search....",
            hintStyle: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF012D1D),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected ? null : Colors.transparent,
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Color(0xFF012D1D), // Premium deep green (kiri)
                          Color(0xFF0D5C3A), // Vibrant emerald green (kanan)
                        ],
                      )
                    : null,
                borderRadius: BorderRadius.circular(20), // Pill shaped
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFF012D1D).withValues(alpha: 0.45),
                        width: 1.8,
                      ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isSelected ? Colors.white : const Color(0xFF012D1D),
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS FOR SHEET CONTENT (DYNAMIC)
  // ---------------------------------------------------------------------------

  Widget _buildLocationPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Your Current Location",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF414844),
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openDefaultLocation,
                  borderRadius: BorderRadius.circular(999),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF4F1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFF012D1D).withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.place_rounded,
                          size: 14,
                          color: Color(0xFF012D1D),
                        ),
                        const SizedBox(width: 5),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 120),
                          child: Text(
                            _defaultLocationLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF012D1D),
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
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onHighlightChanged: (pressed) {
                setState(() => _isMapCardPressed = pressed);
              },
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MapExploreScreen()),
                );
              },
              child: AnimatedScale(
                duration: const Duration(milliseconds: 110),
                curve: Curves.easeOut,
                scale: _isMapCardPressed ? 0.985 : 1,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 110),
                  curve: Curves.easeOut,
                  offset: _isMapCardPressed
                      ? const Offset(0, 0.012)
                      : Offset.zero,
                  child: Ink(
                    height: 184,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: const Color(0xFF012D1D),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: _isMapCardPressed ? 0.028 : 0.05,
                          ),
                          blurRadius: _isMapCardPressed ? 6 : 10,
                          offset: Offset(0, _isMapCardPressed ? 2 : 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: ReusableMapCard(
                              center: _mapCenter,
                              zoom: 13,
                              interactive: false,
                              showCenterPin: true,
                              height: 184,
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.06),
                                  const Color(
                                    0xFF012D1D,
                                  ).withValues(alpha: 0.10),
                                  const Color(
                                    0xFF012D1D,
                                  ).withValues(alpha: 0.26),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.92),
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1A000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.map_outlined,
                                  size: 14,
                                  color: Color(0xFF012D1D),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Explore Map',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF012D1D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFFDF9F4,
                              ).withValues(alpha: 0.94),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF012D1D),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.near_me_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Lihat barang di sekitar kamu',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF012D1D),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Tap buat buka map interaktif dan atur radius',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF5E6762),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEDF2EE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Color(0xFF012D1D),
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
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          image: const DecorationImage(
            image: AssetImage('assets/images/Iklan.jpg'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors
                  .black26, // Overlay gelap tipis agar teks tetap terbaca jelas
              BlendMode.darken,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "SEWAINAJA",
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 28,
                letterSpacing: 1,
                color: Color(0xFFFFF8EF),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "If you can rent it? Why\nwould you buy it?",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                height: 1.3,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _scrollToProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDF9F4),
                foregroundColor: const Color(0xFF012D1D),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                "EXPLORE MORE",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title, {
    bool showSeeMore = true,
    VoidCallback? onSeeMoreTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF414844),
            ),
          ),
          if (showSeeMore)
            GestureDetector(
              onTap: onSeeMoreTap,
              child: const Text(
                "See More...",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF012D1D),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // NEW ARRIVALS — StreamBuilder dari Firestore (limit 5, sort createdAt DESC)
  // ---------------------------------------------------------------------------

  Widget _buildNewArrivals() {
    return StreamBuilder<List<ItemModel>>(
      stream: _itemRepo.watchNewArrivals(limit: 5),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildNewArrivalsLoading();
        }

        // Error atau kosong
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildNewArrivalsEmpty();
        }

        final items = snapshot.data!;

        return SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = items[index];
              final product = ProductData(
                name: item.name,
                price: item.formattedPricePerDay,
                rating: item.ownerRating > 0
                    ? item.ownerRating.toStringAsFixed(1)
                    : '—',
                image: item.primaryPhoto,
              );
              return FadeInUp(
                delay: Duration(milliseconds: 80 * index),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(
                        itemId: item.id,
                        item: item,
                        itemName: item.name,
                        pricePerHour: item.pricePerHour,
                        imagePath: item.primaryPhoto,
                      ),
                    ),
                  ),
                  child: ProductCard(product: product),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNewArrivalsLoading() {
    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => _buildShimmerCard(width: 160, height: 210),
      ),
    );
  }

  Widget _buildNewArrivalsEmpty() {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'Belum ada barang terbaru',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            color: const Color(0xFF414844).withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // MOST TRUSTED NEARBY SLIVER — StreamBuilder dari Firestore + filter kategori
  // ---------------------------------------------------------------------------

  Widget _buildTrustedNearbySliver() {
    return StreamBuilder<List<ItemModel>>(
      stream: _itemRepo.watchAvailableItems(
        categoryName: selectedCategory == 'All' ? null : selectedCategory,
      ),
      builder: (context, snapshot) {
        // Loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              delegate: SliverChildBuilderDelegate(
                (_, __) => _buildShimmerCard(
                  width: double.infinity,
                  height: double.infinity,
                ),
                childCount: 4,
              ),
            ),
          );
        }

        // Error atau kosong
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 48,
                      color: const Color(0xFF012D1D).withValues(alpha: 0.25),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedCategory == 'All'
                          ? 'Belum ada barang tersedia'
                          : 'Tidak ada barang di kategori "$selectedCategory"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: const Color(0xFF414844).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final items = snapshot.data!;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.65,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = items[index];
                final product = ProductData(
                  name: item.name,
                  price: item.formattedPricePerDay,
                  rating: item.ownerRating > 0
                      ? item.ownerRating.toStringAsFixed(1)
                      : '—',
                  image: item.primaryPhoto,
                );
                return FadeInUp(
                  key: ValueKey(
                    '${selectedCategory}_${item.id}_$index',
                  ),
                  delay: Duration(milliseconds: 50 * (index % 4)),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ItemDetailScreen(
                            itemId: item.id,
                            item: item,
                            itemName: item.name,
                            pricePerHour: item.pricePerHour,
                            imagePath: item.primaryPhoto,
                          ),
                        ),
                      );
                    },
                    child: ProductCard(product: product),
                  ),
                );
              },
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SHIMMER PLACEHOLDER CARD saat loading Firestore
  // ---------------------------------------------------------------------------

  Widget _buildShimmerCard({required double width, required double height}) {
    return _ShimmerCard(width: width, height: height);
  }
}

/// Widget shimmer sederhana untuk state loading.
class _ShimmerCard extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerCard({required this.width, required this.height});

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: Color.lerp(
              const Color(0xFFE8E4DC),
              const Color(0xFFF5F1E8),
              _anim.value,
            ),
          ),
        );
      },
    );
  }
}
