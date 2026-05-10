import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'item_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  final List<String> categories = [
    'All',
    'Tech',
    'Power Tools',
    'Outfit',
    'Sport',
    'Camp',
  ];

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
                    const SizedBox(height: 24),

                    // Category Slider (Optimized for Green Background)
                    _buildCategoryFilter(),
                  ],
                ),
              ),
            ),
          ),

          // =============================================================
          // ### [LAYER 2: FOREGROUND / DRAGGABLE WHITE SHEET]
          // =============================================================
          DraggableScrollableSheet(
            initialChildSize: 0.65, // Mulai dari pertengahan layar (65%)
            minChildSize: 0.65, // Tidak bisa diturunkan lebih dari ini
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
                      child: _buildSectionHeader("New Arrivals"),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildNewArrivals()),
                    const SliverToBoxAdapter(child: SizedBox(height: 28)),

                    // 5. SHEET CONTENT 4: TRUSTED NEARBY
                    SliverToBoxAdapter(
                      child: _buildSectionHeader("Most Trusted Nearby"),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    SliverToBoxAdapter(child: _buildTrustedNearby()),

                    // Penutup scroll area agar konten bawah tidak tertutup oleh custom floating navbar
                    const SliverPadding(padding: EdgeInsets.only(bottom: 110)),
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
                  children: const [
                    Icon(
                      Icons.location_on_rounded,
                      size: 12,
                      color: Color(0xFFFDF9F4),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tembalang, Semarang',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: Color(0xFFFDF9F4),
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
                color: isSelected
                    ? Colors.white
                    : const Color(0xFFFFFFFF).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20), // Pill shaped
                border: isSelected
                    ? null
                    : Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1,
                      ),
              ),
              child: Center(
                child: Text(
                  cat,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: isSelected ? const Color(0xFF012D1D) : Colors.white,
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
          Container(
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
              image: const DecorationImage(
                image: AssetImage('assets/images/map_preview.png'),
                fit: BoxFit.cover,
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

  Widget _buildSectionHeader(String title) {
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
          GestureDetector(
            onTap: () {},
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
      _ProductData(
        name: "Sony W830",
        price: "Rp.120,000",
        rating: 4.8,
        image: 'assets/images/sony_camera.png',
      ),
      _ProductData(
        name: "Sony Dual-Sense PS5",
        price: "Rp.45,000",
        rating: 4.8,
        image: 'assets/images/ps5_controller.png',
      ),
      _ProductData(
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
        separatorBuilder: (_, __) => const SizedBox(width: 16),
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
              child: _ProductCard(product: p),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrustedNearby() {
    final product = _ProductData(
      name: "Sony Dual-Sense PS5",
      price: "Rp.45,000",
      rating: 4.8,
      image: 'assets/images/ps5_controller.png',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: FadeInUp(
        delay: const Duration(milliseconds: 100),
        child: GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ItemDetailScreen(),
            ),
          ),
          child: _ProductCard(product: product, isHorizontal: true),
        ),
      ),
    );
  }
}

// Model Data & Card UI Re-definitions

class _ProductData {
  final String name;
  final String price;
  final double rating;
  final String image;

  _ProductData({
    required this.name,
    required this.price,
    required this.rating,
    required this.image,
  });
}

class _ProductCard extends StatelessWidget {
  final _ProductData product;
  final bool isHorizontal;

  const _ProductCard({required this.product, this.isHorizontal = false});

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF012D1D).withOpacity(0.2),
            width: 0.5,
          ), // Border 0.5px
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
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(15),
                ),
                image: DecorationImage(
                  image: AssetImage(product.image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF414844),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF8BD00),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF414844),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      "${product.price}/Day",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF012D1D),
              ),
            ),
          ],
        ),
      );
    }

    // Vertical card for slider
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF012D1D).withOpacity(0.2),
          width: 0.5,
        ), // Card Style: Border 0.5px (#012D1D)
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
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(product.image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF414844),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF8BD00),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      product.rating.toString(),
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF414844),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "${product.price}/Day",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
