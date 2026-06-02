import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'item_detail_screen.dart';
import 'room_chat_screen.dart';
import 'widgets/product_card.dart';
import 'models/product.dart';
import 'see_all_reviews_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  final String ownerName;
  final String? rating;
  final String? listingCount;
  final ImageProvider? avatarImage;

  const ProfileViewScreen({
    super.key,
    this.ownerName = "Mas Tahes",
    this.rating,
    this.listingCount,
    this.avatarImage,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  bool _isFollowing = false;
  String _selectedCategory = "All";
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  
  final List<String> _categories = [
    "All",
    "Tech",
    "Power Tools",
    "Outfit",
    "Camp Tools",
    "Sports",
    "Cook",
  ];
  
  List<Map<String, dynamic>> _ownerProducts = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final List<Map<String, dynamic>> dummyProducts = [
      {
        "name": "Sony W830 #1",
        "price": 120000.0,
        "image": "assets/images/sony_camera.png",
        "category": "Tech",
      },
      {
        "name": "Apple Airpods Max 2",
        "price": 45000.0,
        "image": "assets/images/airpods_max.png",
        "category": "Tech",
      },
      {
        "name": "Sony Dual-Sense PS5",
        "price": 45000.0,
        "image": "assets/images/ps5_controller.png",
        "category": "Tech",
      },
      {
        "name": "Sony a6000 Body Only",
        "price": 150000.0,
        "image": "assets/images/placeholder.png",
        "category": "Tech",
      },
    ];

    try {
      final prefs = await SharedPreferences.getInstance();
      final localItemsStr = prefs.getString('local_user_items') ?? '[]';
      final List<dynamic> localItemsDynamic = jsonDecode(localItemsStr);
      final List<Map<String, dynamic>> localItems = List<Map<String, dynamic>>.from(localItemsDynamic).map((item) {
        // Map the string price back to double for ProfileViewScreen logic
        double parsedPrice = 0.0;
        try {
          String priceStr = item['price'].toString().replaceAll(RegExp(r'[^0-9]'), '');
          parsedPrice = double.parse(priceStr);
        } catch (_) {}
        return {
          "name": item["name"],
          "price": parsedPrice,
          "image": item["image"],
          "category": item["category"],
          "isLocalAsset": item["isLocalAsset"],
        };
      }).toList();
      
      setState(() {
        _ownerProducts = [...localItems, ...dummyProducts];
      });
    } catch (e) {
      debugPrint('Failed to load local items: $e');
      setState(() {
        _ownerProducts = dummyProducts;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    
    // Default Owner Info fallback
    final String displayName = widget.ownerName.trim().isEmpty ? "Mas Tahes" : widget.ownerName;
    final String joinDate = "Member since 2010";
    final String statsFollowers = "103 Followers";
    final String statsListings = widget.listingCount != null ? "${widget.listingCount} Active Listings" : "20+ Active Listings";
    final String aboutMeText = "Passionate gadget & tools enthusiast. I specialize in premium and well-maintained items...";
    final ImageProvider effectiveAvatar = widget.avatarImage ?? const AssetImage("assets/images/profile_user.png");

    // Filtered products listings for owner catalog
    final List<Map<String, dynamic>> filteredProducts = _ownerProducts.where((product) {
      final matchesCategory = _selectedCategory == "All" || product["category"] == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty || product["name"].toString().toLowerCase().contains(_searchQuery);
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF012D1D), // Deep Forest Green Scaffold background
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // LAYER 1: FIXED GREEN BACKGROUND PROFILE HEADER
          // -------------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.40, // Allocating 40% height for header
            child: SafeArea(
              bottom: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 1A. TOP APP BAR ACTION ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Back Button
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: Color(0xFFFDF9F4),
                              size: 20,
                            ),
                          ),
                        ),
                        // Share Button
                        GestureDetector(
                          onTap: () {
                            // Dummy share action
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Membagikan profil $displayName...'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.share,
                              color: Color(0xFFFDF9F4),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- 1B. OWNER MAIN INFO ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar Box with Rating Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                image: DecorationImage(
                                  image: effectiveAvatar,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            // Rating Badge
                            Positioned(
                              bottom: -6,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8BD00), // Yellow Gold
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 10,
                                        color: Color(0xFF012D1D),
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        widget.rating ?? "4.3",
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Color(0xFF012D1D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Owner details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Color(0xFFFDF9F4),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.verified,
                                    color: Color(0xFFF8BD00),
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                joinDate,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.normal,
                                  fontSize: 12,
                                  color: const Color(0xFFFDF9F4).withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Stats Row
                              Text(
                                "$statsFollowers   •   $statsListings",
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 12,
                                  color: Color(0xFFFDF9F4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- 1C. ACTION BUTTONS ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
                        // Follow Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isFollowing = !_isFollowing;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing ? Colors.transparent : const Color(0xFFF8BD00),
                              foregroundColor: _isFollowing ? const Color(0xFFFDF9F4) : const Color(0xFF012D1D),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: _isFollowing ? const BorderSide(color: Color(0xFFFDF9F4), width: 1) : BorderSide.none,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              _isFollowing ? "Unfollow" : "Follow",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Message Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomChatScreen(
                                    chatPartnerName: displayName,
                                  ),
                                ),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFFDF9F4),
                              side: const BorderSide(color: Color(0xFFFDF9F4), width: 1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              "Message",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // LAYER 2: DRAGGABLE SCROLLABLE SHEET (BODY CONTENT)
          // -------------------------------------------------------------------
          NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              return true;
            },
            child: DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.65,
              maxChildSize: 1.0,
              snap: true,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFF8EF), // Cream sheet background
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: CustomScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      // --- DRAG HANDLE & SECTIONS ---
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Drag Handle Bar
                            Center(
                              child: Container(
                                width: 40,
                                height: 5,
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD6C7A1).withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // --- 2A. ABOUT ME SECTION ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "ABOUT ME",
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF414844),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    aboutMeText,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.normal,
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Color(0xFF414844),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // --- 2B. STRENGTHS BADGE SECTION ---
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children: [
                                  _buildStrengthChip("Fast Communication (3)"),
                                  _buildStrengthChip("Fair Pricing (2)"),
                                ],
                              ),
                            ),

                            // Divider
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              color: const Color(0xFF414844).withValues(alpha: 0.2),
                            ),

                            // --- 2C. REVIEWS PREVIEW SECTION ---
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "User Reviews",
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF414844),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => SeeAllReviewsScreen(
                                                ownerName: widget.ownerName,
                                              ),
                                            ),
                                          );
                                        },
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          "Lihat semua",
                                          style: TextStyle(
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF012D1D),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Review Cards Slider
                                SizedBox(
                                  height: 135,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    children: [
                                      _buildReviewCard("Ceazar", "Dec 30, 2025", 5, "Barang ori, kondisinya mulus banget pas disewa..."),
                                      const SizedBox(width: 12),
                                      _buildReviewCard("Budi", "Nov 15, 2025", 4, "Pelayanan mantap, respon cepat."),
                                      const SizedBox(width: 12),
                                      _buildReviewCard("Ayu", "Oct 02, 2025", 5, "Sangat recommended, ramah sekali ownernya."),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            // Divider
                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              color: const Color(0xFF414844).withValues(alpha: 0.2),
                            ),

                            // --- 2D. OWNER LISTINGS (CATALOG) ---
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Text(
                                    "${displayName}s Listings",
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF414844),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),

                                // Mini Search Bar
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (val) {
                                        setState(() {
                                          _searchQuery = val.trim().toLowerCase();
                                        });
                                      },
                                      textAlignVertical: TextAlignVertical.center,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        color: Color(0xFF012D1D),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        border: InputBorder.none,
                                        prefixIcon: const Icon(Icons.search, color: Color(0xFF012D1D), size: 20),
                                        prefixIconConstraints: const BoxConstraints(
                                          minWidth: 40,
                                          minHeight: 20,
                                        ),
                                        hintText: "Search listings...",
                                        hintStyle: const TextStyle(
                                          fontFamily: 'Poppins',
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                        suffixIcon: _searchQuery.isNotEmpty
                                            ? IconButton(
                                                icon: const Icon(Icons.clear, size: 16, color: Color(0xFF012D1D)),
                                                onPressed: () {
                                                  _searchController.clear();
                                                  setState(() {
                                                    _searchQuery = "";
                                                  });
                                                },
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Category Slide (Matches Most Trusted Nearby filter)
                                SizedBox(
                                  height: 40,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 24),
                                    physics: const BouncingScrollPhysics(),
                                    itemCount: _categories.length,
                                    separatorBuilder: (context, _) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final cat = _categories[index];
                                      final isSelected = cat == _selectedCategory;
                                      return GestureDetector(
                                        onTap: () => setState(() => _selectedCategory = cat),
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
                                                      Color(0xFF012D1D),
                                                      Color(0xFF0D5C3A),
                                                    ],
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(20),
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
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Listing Grid (SliverGrid)
                      filteredProducts.isEmpty
                          ? SliverToBoxAdapter(
                              child: Container(
                                height: 200,
                                alignment: Alignment.center,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 48,
                                      color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      "Tidak ada barang yang cocok",
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF414844),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SliverPadding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              sliver: SliverGrid(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.65,
                                ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                    final productMap = filteredProducts[index];
                                    final product = ProductData(
                                      name: productMap["name"],
                                      price: "Rp. ${productMap["price"].toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                                      image: productMap["image"],
                                      rating: 4.5, // Dummy rating
                                      isLocalAsset: productMap["isLocalAsset"] ?? false,
                                    );
                                    return FadeInUp(
                                      duration: const Duration(milliseconds: 400),
                                      delay: Duration(milliseconds: 50 * index),
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ItemDetailScreen(
                                                itemName: product.name,
                                                pricePerHour: productMap["price"] / 24, // Convert daily price dummy to hourly
                                                sellerLocation: "Tembalang, Banyumanik",
                                                imagePath: productMap["image"],
                                                isLocalAsset: product.isLocalAsset,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ProductCard(product: product),
                                      ),
                                    );
                                  },
                                  childCount: filteredProducts.length,
                                ),
                              ),
                            ),

                      // Grid bottom padding spacer
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Helper builder for Strength Chips
  Widget _buildStrengthChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF012D1D).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
          fontSize: 12,
          color: Color(0xFF012D1D),
        ),
      ),
    );
  }

  // Helper builder for Review Cards
  Widget _buildReviewCard(String name, String date, int rating, String reviewText) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF012D1D).withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0] : 'U',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012D1D),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF414844),
                  ),
                ),
              ),
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Stars
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 12,
                color: index < rating ? const Color(0xFFF8BD00) : Colors.grey.shade300,
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            reviewText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.normal,
              fontSize: 12,
              color: Color(0xFF414844),
            ),
          ),
        ],
      ),
    );
  }
}
