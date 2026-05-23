import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'address_service.dart';
import 'item_detail_screen.dart';
import 'map_common_widgets.dart';
import 'map_explore_screen.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'new_arrivals_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const LatLng _fallbackCenter = LatLng(-6.966667, 110.416664);
  final AddressService _addressService = const AddressService();
  String selectedCategory = 'All';
  String _defaultLocationLabel = 'Tembalang, Semarang';
  LatLng _mapCenter = _fallbackCenter;
  final List<String> categories = [
    'All',
    'Tech',
    'Power Tools',
    'Outfit',
    'Sport',
    'Camp',
  ];

  @override
  void initState() {
    super.initState();
    _loadDefaultLocationLabel();
  }

  Future<void> _loadDefaultLocationLabel() async {
    final prefs = await SharedPreferences.getInstance();
    final label = prefs.getString('user_default_location')?.trim();
    final lat = prefs.getDouble('user_default_lat');
    final lng = prefs.getDouble('user_default_lng');
    if (!mounted) return;
    setState(() {
      if (label != null && label.isNotEmpty) {
        _defaultLocationLabel = label;
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
      // Memastikan background root berwarna hijau sesuai spesifikasi Layer 1
      backgroundColor: const Color(0xFF012D1D),
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
                    // Profile Row
                    _buildHeader(),
                    const SizedBox(height: 24),

                    // White Search Bar
                    _buildSearchBar(),
                  ],
                ),
              ),
            ),
          ),

          // =============================================================
          // ### [LAYER 2: FOREGROUND / DRAGGABLE WHITE SHEET]
          // =============================================================
          DraggableScrollableSheet(
            initialChildSize: 0.76, // Di-adjust naik agar lebih dekat dengan search bar
            minChildSize: 0.76, // Tidak bisa diturunkan lebih dari ini
            maxChildSize: 1.0, // Bisa ditarik sampai atas
            snap: true, // Menambahkan efek magnet agar lebih premium
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(
                    0xFFFFF8EF,
                  ), // Background Color: #FFF8EF (Cream Canvas)
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
                    // 1. DRAG HANDLE TOP INDICATOR
                    SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6C7A1).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),

                    // 2. SHEET CONTENT 1: PROMO BANNER AREA
                    const SliverPadding(padding: EdgeInsets.only(top: 8)),
                    SliverToBoxAdapter(child: _buildPromoBanner()),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // 3. SHEET CONTENT 2: LOCATION & MAPPING
                    SliverToBoxAdapter(child: _buildLocationPreview()),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // 4. SHEET CONTENT 3: NEW ARRIVALS HEADER & SLIDER
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

                    // 5. SHEET CONTENT 4: TRUSTED NEARBY
                    SliverToBoxAdapter(
                      child: _buildSectionHeader("Most Trusted Nearby", showSeeMore: false),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildCategoryFilter()),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    _buildTrustedNearbySliver(),

                    // Penutup scroll area agar konten bawah tidak terlalu mepet
                    const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                  ],
                ),
              );
            },
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
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              image: const DecorationImage(
                image: AssetImage('assets/images/profile_user.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Han Soo Hee',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFFDF9F4),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFFFDF9F4),
                      ),
                    ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 22,
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
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const TextField(
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            prefixIcon: Icon(
              Icons.search,
              color: Color(0xFF012D1D), // Placeholder "#012D1D"
            ),
            hintText: "Search....",
            hintStyle: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF012D1D),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 14),
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
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF012D1D)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20), // Pill shaped
                border: isSelected
                    ? null
                    : Border.all(
                        color: const Color(0xFF012D1D).withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isSelected ? Colors.white : const Color(0xFF012D1D),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
          const Text(
            "Your Current Location",
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF414844),
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapExploreScreen()),
              );
            },
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFF012D1D), width: 0.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: ReusableMapCard(
                  center: _mapCenter,
                  zoom: 13,
                  interactive: false,
                  showCenterPin: true,
                  overlayLabel: _defaultLocationLabel,
                  height: 160,
                  borderRadius: BorderRadius.circular(25),
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
              color: Colors.black.withOpacity(0.1),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ItemDetailScreen(),
                  ),
                );
              },
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

  Widget _buildNewArrivals() {
    final products = [
      ProductData(
        name: "Sony W830",
        price: "Rp.120,000",
        rating: 4.8,
        image: 'assets/images/sony_camera.png',
      ),
      ProductData(
        name: "Sony Dual-Sense PS5",
        price: "Rp.45,000",
        rating: 4.8,
        image: 'assets/images/ps5_controller.png',
      ),
      ProductData(
        name: "Apple Airpods Max 2",
        price: "Rp.45,000",
        rating: 4.8,
        image: 'assets/images/airpods_max.png',
      ),
    ];

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final p = products[index];
          return FadeInUp(
            delay: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemDetailScreen(),
                ),
              ),
              child: ProductCard(product: p),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrustedNearbySliver() {
    final baseProducts = [
      ProductData(
        name: "Sony W830",
        price: "Rp.120,000",
        rating: 4.8,
        image: 'assets/images/sony_camera.png',
      ),
      ProductData(
        name: "Sony Dual-Sense PS5",
        price: "Rp.45,000",
        rating: 4.8,
        image: 'assets/images/ps5_controller.png',
      ),
      ProductData(
        name: "Apple Airpods Max 2",
        price: "Rp.45,000",
        rating: 4.8,
        image: 'assets/images/airpods_max.png',
      ),
    ];

    final products = List.generate(50, (index) {
      final base = baseProducts[index % baseProducts.length];
      return ProductData(
        name: "${base.name} #${index + 1}",
        price: base.price,
        rating: base.rating,
        image: base.image,
      );
    });

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final product = products[index];
            return FadeInUp(
              delay: Duration(milliseconds: 50 * (index % 4)),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ItemDetailScreen(),
                  ),
                ),
                child: ProductCard(product: product, isHorizontal: false),
              ),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }
}
