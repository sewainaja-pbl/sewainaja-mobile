import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
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
import 'widgets/product_more_sheet.dart';
import 'widgets/subtle_fade_in.dart';
import 'favorite_service.dart';
import 'widgets/report_dialog.dart';
import 'new_arrivals_screen.dart';
import 'notification_screen.dart';
import 'search_screen.dart';
import 'search_result_screen.dart';
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
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen>
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

  // Caching variables for Firestore streams to optimize performance
  StreamSubscription<List<ItemModel>>? _newArrivalsSub;
  StreamSubscription<List<ItemModel>>? _trustedNearbySub;
  List<ItemModel>? _newArrivals;
  List<ItemModel>? _trustedNearby;
  bool _isLoadingNewArrivals = true;
  bool _isLoadingTrustedNearby = true;
  
  List<ItemModel>? _followingItems;
  bool _isLoadingFollowing = true;

  // Kategori dari Firestore + "All" selalu ada di depan
  List<String> _firestoreCategories = [];

  // Search state shared with SearchScreen
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearchActive = false;
  final GlobalKey<SearchSheetState> _searchSheetKey =
      GlobalKey<SearchSheetState>();

  // Scroll controller for main view
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _trustedSectionKey = GlobalKey();
  bool _isMapCardPressed = false;
  bool _showBackToTop = false;

  // Single shared animation controller for all skeleton shimmers to optimize performance
  late AnimationController _shimmerController;
  Timer? _timeTimer;
  String _currentTimeString = '';

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
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _updateShimmerControllerStatus();
    _loadDefaultLocationLabel();
    _loadCategories();
    _listenToNewArrivals();
    _listenToTrustedNearby();
    _updateTime();
    _timeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateTime();
    });
    _loadFollowingItems();
    _scrollController.addListener(() {
      final show = _scrollController.offset > 300;
      if (show != _showBackToTop) {
        setState(() {
          _showBackToTop = show;
        });
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB";
    if (_currentTimeString != timeStr) {
      if (mounted) {
        setState(() {
          _currentTimeString = timeStr;
        });
      }
    }
  }

  void scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _handleRefresh() async {
    await _loadDefaultLocationLabel();
    await _loadCategories();
    _listenToNewArrivals();
    _listenToTrustedNearby();
    await _loadFollowingItems();
  }

  Future<void> _loadFollowingItems() async {
    setState(() {
      _isLoadingFollowing = true;
    });
    try {
      final items = await _itemRepo.getFollowingItems();
      if (!mounted) return;
      setState(() {
        _followingItems = items;
        _isLoadingFollowing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _followingItems = [];
        _isLoadingFollowing = false;
      });
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _newArrivalsSub?.cancel();
    _trustedNearbySub?.cancel();
    _timeTimer?.cancel();
    super.dispose();
  }

  void _updateShimmerControllerStatus() {
    if (_isLoadingNewArrivals || _isLoadingTrustedNearby) {
      if (!_shimmerController.isAnimating) {
        _shimmerController.repeat(reverse: true);
      }
    } else {
      if (_shimmerController.isAnimating) {
        _shimmerController.stop();
      }
    }
  }

  void _listenToNewArrivals() {
    _newArrivalsSub?.cancel();
    setState(() {
      _isLoadingNewArrivals = true;
      _updateShimmerControllerStatus();
    });
    _newArrivalsSub = _itemRepo.watchNewArrivals(limit: 5).listen((items) {
      if (!mounted) return;
      setState(() {
        _newArrivals = items;
        _isLoadingNewArrivals = false;
        _updateShimmerControllerStatus();
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingNewArrivals = false;
        _updateShimmerControllerStatus();
      });
    });
  }

  void _listenToTrustedNearby() {
    _trustedNearbySub?.cancel();
    setState(() {
      _isLoadingTrustedNearby = true;
      _updateShimmerControllerStatus();
    });
    _trustedNearbySub = _itemRepo.watchAvailableItems(
      categoryName: selectedCategory == 'All' ? null : selectedCategory,
    ).listen((items) {
      if (!mounted) return;
      setState(() {
        _trustedNearby = items;
        _isLoadingTrustedNearby = false;
        _updateShimmerControllerStatus();
      });
    }, onError: (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingTrustedNearby = false;
        _updateShimmerControllerStatus();
      });
    });
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchSheetKey.currentState?.closeAsync().then((_) {
      _searchController.clear();
      if (mounted) {
        setState(() => _isSearchActive = false);
        widget.onSearchActiveChanged?.call(false);
      }
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
    final wasNotAll = selectedCategory != 'All';
    setState(() {
      selectedCategory = 'All';
    });
    if (wasNotAll) {
      _listenToTrustedNearby();
    }
    try {
      final context = _trustedSectionKey.currentContext;
      if (context != null) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _scrollController.animateTo(
          380,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    } catch (_) {
      _scrollController.animateTo(
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
      backgroundColor: const Color(0xFFFFF8EF),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _handleRefresh,
            color: const Color(0xFF012D1D),
            backgroundColor: const Color(0xFFFFF8EF),
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFF012D1D),
                  pinned: false,
                  floating: false,
                  expandedHeight: 200,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                        const SizedBox(height: 36),
                      ],
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(20),
                    child: Container(
                      height: 20,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF8EF),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6C7A1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Column(
                      children: [
                        _buildPromoBanner(),
                        const SizedBox(height: 28),
                        _buildLocationPreview(),
                        const SizedBox(height: 28),
                        _buildFollowingSection(),
                        _buildSectionHeader(
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
                        const SizedBox(height: 16),
                        _buildNewArrivals(),
                        const SizedBox(height: 28),
                        Container(
                          key: _trustedSectionKey,
                          child: _buildSectionHeader(
                            "Most Trusted Nearby",
                            showSeeMore: false,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryFilter(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                _buildTrustedNearbySliver(),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            ),
          ),

          if (_showBackToTop)
            Positioned(
              right: 20,
              bottom: 110,
              child: FloatingActionButton(
                mini: false,
                onPressed: scrollToTop,
                backgroundColor: const Color(0xFF012D1D),
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                elevation: 4,
                child: const Icon(Icons.keyboard_arrow_up_rounded, size: 28),
              ),
            ),

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
                  image: (!_profilePhotoUrl.startsWith('http://') && !_profilePhotoUrl.startsWith('https://'))
                      ? const ResizeImage(AssetImage('assets/images/profile_user.png'), width: 90)
                      : _imageUploadService.buildImageProvider(_profilePhotoUrl, targetWidth: 90),
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
          onSubmitted: (value) {
            final query = value.trim();
            if (query.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultScreen(searchQuery: query),
                ),
              );
            }
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
            onTap: () {
              if (selectedCategory == cat) return;
              setState(() {
                selectedCategory = cat;
              });
              _listenToTrustedNearby();
            },
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
              borderRadius: BorderRadius.circular(24),
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
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF012D1D).withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: IgnorePointer(
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: RepaintBoundary(
                              child: ReusableMapCard(
                                center: _mapCenter,
                                zoom: 13,
                                interactive: false,
                                showCenterPin: true,
                                height: 180,
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                          // Top Left Badge
                          Positioned(
                            top: 12,
                            left: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _currentTimeString.isNotEmpty ? _currentTimeString : "20:10 WIB",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF012D1D),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Top Right Action
                          Positioned(
                            top: 12,
                            right: 12,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.open_in_full_rounded,
                                    color: Color(0xFF012D1D),
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Bottom Info Bar
                          Positioned(
                            bottom: 12,
                            left: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF012D1D),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_rounded,
                                          color: Color(0xFFFDF9F4),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _defaultLocationLabel.isNotEmpty
                                                ? _defaultLocationLabel
                                                : "Semarang, Indonesia",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontFamily: 'Poppins',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFFFDF9F4),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "5 km",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFFFDF9F4).withValues(alpha: 0.7),
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
            image: ResizeImage(AssetImage('assets/images/Iklan.jpg'), width: 600),
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

  Widget _buildFollowingSection() {
    if (_isLoadingFollowing || _followingItems == null || _followingItems!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("From Your Following", showSeeMore: false),
        const SizedBox(height: 16),
        SizedBox(
          height: 210,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            itemCount: _followingItems!.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = _followingItems![index];
              final product = ProductData(
                id: item.id,
                name: item.name,
                price: item.formattedPrice,
                rating: item.ownerRating > 0
                    ? item.ownerRating.toStringAsFixed(1)
                    : '—',
                image: item.primaryPhoto,
                originalItem: item,
              );
              return SubtleFadeIn(
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
                  child: ProductCard(
                    product: product,
                    heroTagPrefix: 'following-',
                    onMorePressed: () => _showProductOptions(context, item, product),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // NEW ARRIVALS — StreamBuilder dari Firestore (limit 5, sort createdAt DESC)
  // ---------------------------------------------------------------------------

  Widget _buildNewArrivals() {
    if (_isLoadingNewArrivals || _newArrivals == null) {
      return _buildNewArrivalsLoading();
    }

    if (_newArrivals!.isEmpty) {
      return _buildNewArrivalsEmpty();
    }

    final items = _newArrivals!;

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
            id: item.id,
            name: item.name,
            price: item.formattedPrice,
            rating: item.ownerRating > 0
                ? item.ownerRating.toStringAsFixed(1)
                : '—',
            image: item.primaryPhoto,
            originalItem: item,
          );
          return SubtleFadeIn(
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
              child: ProductCard(
                product: product,
                heroTagPrefix: 'new-arrivals-',
                onMorePressed: () => _showProductOptions(context, item, product),
              ),
            ),
          );
        },
      ),
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
        itemBuilder: (_, __) => ProductCardSkeleton(
          width: 160,
          height: 210,
          animation: _shimmerController,
        ),
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
    if (_isLoadingTrustedNearby || _trustedNearby == null) {
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
            (_, __) => ProductCardSkeleton(
              width: double.infinity,
              height: double.infinity,
              animation: _shimmerController,
            ),
            childCount: 4,
          ),
        ),
      );
    }

    if (_trustedNearby!.isEmpty) {
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

    final items = _trustedNearby!;

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
              id: item.id,
              name: item.name,
              price: item.formattedPrice,
              rating: item.ownerRating > 0
                  ? item.ownerRating.toStringAsFixed(1)
                  : '—',
              image: item.primaryPhoto,
            );
            return SubtleFadeIn(
              key: ValueKey(
                '${selectedCategory}_${item.id}_$index',
              ),
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
                child: ProductCard(
                  product: product,
                  heroTagPrefix: 'trusted-',
                  onMorePressed: () => _showProductOptions(context, item, product),
                ),
              ),
            );
          },
          childCount: items.length,
        ),
      ),
    );
  }

  void _showProductOptions(BuildContext context, ItemModel item, ProductData product) async {
    final isFav = await FavoriteService.isFavorite(item.id);
    if (!context.mounted) return;
    showProductMoreSheet(
      context: context,
      product: product,
      isFavorite: isFav,
      onFavoritePressed: () async {
        final nowFav = await FavoriteService.toggleFavorite(item.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              nowFav ? '${item.name} disimpan ke Favorit!' : '${item.name} dihapus dari Favorit!',
              style: const TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: const Color(0xFF012D1D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onSimilarPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultScreen(
              searchQuery: item.name,
            ),
          ),
        );
      },
      onNotInterestedPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Rekomendasi disesuaikan. Kami akan mengurangi rekomendasi serupa.',
              style: TextStyle(fontFamily: 'Poppins'),
            ),
            backgroundColor: Color(0xFF012D1D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      onReportPressed: () {
        if (item.ownerId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data pemilik tidak ditemukan.', style: TextStyle(fontFamily: 'Poppins')),
              backgroundColor: Color(0xFFE33629),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        showReportDialog(
          context,
          reportedId: item.ownerId,
          itemId: item.id,
          itemName: item.name,
        );
      },
    );
  }

}

/// Widget skeleton loading terstruktur yang meniru layout ProductCard vertikal
/// menggunakan satu controller animasi bersama dari parent.
class ProductCardSkeleton extends StatelessWidget {
  final double width;
  final double height;
  final Animation<double> animation;

  const ProductCardSkeleton({
    super.key,
    required this.width,
    required this.height,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final shimmerColor = Color.lerp(
          const Color(0xFFE8E4DC),
          const Color(0xFFF5F1E8),
          animation.value,
        )!;
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFF2F6743), width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Area Gambar (Placeholder)
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: shimmerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Area Nama/Judul Barang (Placeholder)
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 100,
                  height: 12,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                // Area Harga Barang (Placeholder)
                Container(
                  width: 70,
                  height: 14,
                  decoration: BoxDecoration(
                    color: shimmerColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
