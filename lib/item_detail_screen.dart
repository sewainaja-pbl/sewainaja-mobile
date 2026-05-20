import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'ajukan_sewa_screen.dart';
import 'map_common_widgets.dart';

class ItemDetailScreen extends StatefulWidget {
  final String? itemName;
  final double? pricePerHour;
  final String? sellerLocation;

  const ItemDetailScreen({
    super.key,
    this.itemName,
    this.pricePerHour,
    this.sellerLocation,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  // State variable untuk expand/collapse deskripsi
  bool isDescriptionExpanded = false;
  final LatLng _itemCenter = const LatLng(-6.9791, 110.4208);

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    const double heroImageHeightFactor = 0.40;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Base canvas color
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // Layer 1 (Dasar): IMAGE BACKGROUND & TOP ACTIONS
          // -------------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * heroImageHeightFactor, // Hero image height
            child: Image.asset(
              'assets/images/Iklan.jpg', // Menggunakan Iklan.jpg sesuai user prompt
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // -------------------------------------------------------------------
          // Layer 2 (Tengah): SCROLLABLE PRODUCT INFO SHEET
          // -------------------------------------------------------------------
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Spacer Transparan agar sheet tidak menutupi gambar secara default di atas
                  SizedBox(height: (screenHeight * heroImageHeightFactor) - 30),

                  // ### [SECTION 2: SCROLLABLE PRODUCT INFO SHEET]
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDF9F4), // ID: '259:1971'
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 2A. MAIN INFO ---
                          _buildTitleAndBadges(),
                          const SizedBox(height: 24),

                          // Divider
                          const Divider(
                            height: 1,
                            color: Color(0xFFE0E0E0),
                            thickness: 1,
                          ),
                          const SizedBox(height: 24),

                          // --- 2D. DESCRIPTION SECTION (With Toggle logic) ---
                          _buildDescription(),
                          const SizedBox(height: 32),

                          // --- 2B. SELLER PROFILE CARD ---
                          _buildSellerProfileCard(),
                          const SizedBox(height: 32),

                          // --- 2C. LOCATION RADIUS MAP ---
                          _buildLocationRadiusMap(),
                          const SizedBox(height: 32),

                          // --- 2E. RECOMMENDATION SLIDER ---
                          _buildRecommendationSlider(),

                          // Padding bottom sangat penting agar konten tidak tertutup Bottom Action Bar (Layer 3)
                          const SizedBox(height: 130),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Layer Navigasi Mengambang di Atas Gambar
          // -------------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Left Action: Back Button
                    _buildCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    // Top Right Actions
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: Icons.share_rounded,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _buildCircleButton(
                          icon: Icons.more_vert_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Layer 3 (Atas): BOTTOM ACTION BAR (Melayang Fixed)
          // -------------------------------------------------------------------
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(),
          ),
        ],
      ),
    );
  }

  // Helper: Floating Circle Button
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFF012D1D), // Circle Background: #012D1D
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFFFDF9F4), // Icon Color: #FDF9F4
        ),
      ),
    );
  }

  // 2A. MAIN INFO
  Widget _buildTitleAndBadges() {
    final itemName = widget.itemName ?? "Sony Camera a6000";
    final itemPrice = widget.pricePerHour != null
        ? "Rp. ${widget.pricePerHour!.toStringAsFixed(0)},00/jam"
        : "Rp. 15.000,00/jam";
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName, // ID: '259:1979'
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    itemPrice, // ID: '259:1980'
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Color(0xFF7B5804), // Color_Accent_Brown
                    ),
                  ),
                ],
              ),
            ),
            // Action: Heart/Like Icon
            Container(
              margin: const EdgeInsets.only(top: 4),
              child: const Icon(
                Icons.favorite_border_rounded,
                size: 28,
                color: Color(0xFFE33629), // Color_Danger_Red
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Badge Like New
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF22C23A), // Background: #22C23A
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Text(
                "Like New",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Clock Info
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: Colors.black54,
            ),
            const SizedBox(width: 6),
            const Text(
              "2 hari lalu",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 2D. DESCRIPTION SECTION (DENGAN EXPAND TOGGLE)
  Widget _buildDescription() {
    const String fullDescription =
        "Sony a6000 adalah kamera mirrorless APS-C 24,3 MP yang andal, populer untuk pemula dan traveling karena ukurannya ringkas, autofokus cepat (11 fps), dan harga terjangkau. Kondisi barang sangat terawat, lensa bersih tanpa jamur sama sekali. Cocok untuk pemula hingga profesional untuk event fotografi maupun videografi ringan. Termasuk tas kamera, 1 baterai ekstra, dan charger bawaan.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Description", // ID: '270:1322'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600, // SemiBold
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            // Toggle Show More / Less
            GestureDetector(
              onTap: () {
                setState(() {
                  isDescriptionExpanded = !isDescriptionExpanded;
                });
              },
              child: Row(
                children: [
                  Text(
                    isDescriptionExpanded
                        ? "See less"
                        : "See more", // ID: '270:1324'
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  Icon(
                    isDescriptionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF012D1D),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          child: Text(
            fullDescription, // ID: '270:1327'
            maxLines: isDescriptionExpanded ? null : 2,
            overflow: isDescriptionExpanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter', // Dinyatakan khusus dalam spesifikasi
              fontWeight: FontWeight.w300, // Light / 300
              fontSize: 12,
              height: 1.6,
              color: Color(0xFF414844),
            ),
          ),
        ),
      ],
    );
  }

  // 2B. SELLER PROFILE CARD
  Widget _buildSellerProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, // ID: '259:1991'
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.black, // Border: 1px Solid #000000
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar Image
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: const DecorationImage(
                image: AssetImage('assets/images/profile_user.png'),
                fit: BoxFit.cover,
              ),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
          ),
          const SizedBox(width: 12),
          // Seller Name & Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Han Soo Hee",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500, // Regular to Medium
                    fontSize: 12,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFF8BD00),
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "4.9",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      "| ${widget.sellerLocation ?? "Tembalang, Banyumanik"}",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Chat Action Button
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF012D1D).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const FaIcon(
              FontAwesomeIcons.solidCommentDots,
              size: 16,
              color: Color(0xFF012D1D),
            ),
          ),
        ],
      ),
    );
  }

  // 2C. LOCATION RADIUS MAP
  Widget _buildLocationRadiusMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Radius Lokasi Barang", // ID: '259:1972'
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25), // ID: '259:1977'
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ReusableMapCard(
            center: _itemCenter,
            zoom: 13.5,
            radiusKm: 3,
            interactive: false,
            markers: [MapMarkerData(point: _itemCenter, highlighted: true)],
            overlayLabel: 'Estimasi jangkauan 3 km dari titik barang',
            borderRadius: BorderRadius.circular(25),
            height: 180,
          ),
        ),
      ],
    );
  }

  // 2E. RECOMMENDATION SLIDER (Horizontal Scroll)
  Widget _buildRecommendationSlider() {
    final List<Map<String, String>> recommendedProducts = [
      {
        "name": "Sony W830",
        "price": "Rp.120,000",
        "image": "assets/images/sony_camera.png",
      },
      {
        "name": "Apple Airpods Max 2",
        "price": "Rp.45,000",
        "image": "assets/images/airpods_max.png",
      },
      {
        "name":
            "Keyboard Mahal", // Placeholder visual using PS5 controller for correctness
        "price": "Rp.45,000",
        "image": "assets/images/ps5_controller.png",
      },
      {
        "name": "Occulus VR", // Placeholder visual reuse PS5 controller
        "price": "Rp.120,000",
        "image": "assets/images/ps5_controller.png",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommendation", // ID: '277:2085'
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600, // SemiBold
            fontSize: 20,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190, // Tinggi list slider
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: recommendedProducts.length,
            separatorBuilder: (_, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final item = recommendedProducts[index];
              return _RecommendationCardItem(
                name: item["name"]!,
                price: item["price"]!,
                image: item["image"]!,
              );
            },
          ),
        ),
      ],
    );
  }

  // SECTION 3: FIXED BOTTOM ACTION BAR (Positioned on Stack bottom)
  Widget _buildBottomActionBar() {
    return Container(
      // Gradasi halus agar menyatu dengan latar (Optional tapi ditambahkan untuk premium feel)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFDF9F4).withValues(alpha: 0.0),
            const Color(0xFFFDF9F4).withValues(alpha: 0.9),
            const Color(0xFFFDF9F4),
          ],
          stops: const [0.0, 0.2, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Secondary Action: Chat Button Icon
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white, // Frame putih melingkar
                border: Border.all(color: const Color(0xFF012D1D), width: 1.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: FaIcon(
                  FontAwesomeIcons.solidComments, // ID: '259:2031'
                  color: Color(0xFF012D1D),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Primary Action: Sewa Sekarang Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AjukanSewaScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF012D1D), // ID: '259:2029'
                    borderRadius: BorderRadius.circular(277), // Pill shape
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      "Sewa Sekarang",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700, // Bold
                        fontSize: 16,
                        color: Color(0xFFFDF9F4), // Text Color
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ITEM COMPONENT UNTUK RECOMMENDATION SLIDER
class _RecommendationCardItem extends StatelessWidget {
  final String name;
  final String price;
  final String image;

  const _RecommendationCardItem({
    required this.name,
    required this.price,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 145,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFF012D1D).withValues(alpha: 0.1),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar produk rekomen
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                  image: AssetImage(image),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // Text Detail
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF414844),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$price/Day",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
