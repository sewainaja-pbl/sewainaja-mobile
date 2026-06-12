import 'package:flutter/material.dart';
import 'item_detail_screen.dart';
import 'room_chat_screen.dart';
import 'widgets/product_card.dart';
import 'widgets/subtle_fade_in.dart';
import 'widgets/product_more_sheet.dart';
import 'search_result_screen.dart';
import 'models/product.dart';
import 'see_all_reviews_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/report_dialog.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/rating_repository.dart';
import 'data/repositories/item_repository.dart';
import 'data/models/item_model.dart';
import 'add_product_screen.dart';
import 'package:http/http.dart' as http;
import 'auth_session_service.dart';
import 'api_config.dart';
import 'app_feedback.dart';

class ProfileViewScreen extends StatefulWidget {
  final String? ownerId;
  final String ownerName;
  final String? rating;
  final String? listingCount;
  final ImageProvider? avatarImage;

  const ProfileViewScreen({
    super.key,
    this.ownerId,
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
  
  late String _targetOwnerId;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  late Stream<List<ItemModel>> _itemsStream;
  late Stream<List<Map<String, dynamic>>> _reviewsStream;

  final UserRepository _userRepo = UserRepository();
  final RatingRepository _ratingRepo = RatingRepository();
  final ItemRepository _itemRepo = ItemRepository();

  @override
  void initState() {
    super.initState();
    _targetOwnerId = widget.ownerId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    print('[ProfileViewScreen] initState: widget.ownerId = "${widget.ownerId}", _targetOwnerId = "$_targetOwnerId"');
    _loadProfile();
    if (_targetOwnerId.isNotEmpty) {
      _itemsStream = _itemRepo.watchItemsByOwner(_targetOwnerId);
      _reviewsStream = _ratingRepo.watchOwnerReviews(_targetOwnerId, limit: 5);
    } else {
      _itemsStream = const Stream.empty();
      _reviewsStream = const Stream.empty();
    }
  }

  Future<void> _loadProfile() async {
    if (_targetOwnerId.isEmpty) {
      if (mounted) setState(() => _isLoadingProfile = false);
      return;
    }
    print('[ProfileViewScreen] _loadProfile: fetching profile for "$_targetOwnerId"');
    final profile = await _userRepo.getUserProfile(_targetOwnerId);
    print('[ProfileViewScreen] _loadProfile: fetched profile = $profile');
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  // _loadItems removed

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF8EF),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF012D1D))),
      );
    }

    final String displayName = _userProfile?['name'] ?? (widget.ownerName.trim().isEmpty ? "Mas Tahes" : widget.ownerName);
    final double ratingNum = (_userProfile?['avgRatingAsOwner'] as num?)?.toDouble() ?? double.tryParse(widget.rating ?? '') ?? 0.0;
    final String displayRating = ratingNum > 0 ? ratingNum.toStringAsFixed(1) : (widget.rating ?? "4.3");
    
    final dynamic rawCreatedAt = _userProfile?['createdAt'];
    String joinDate = "Member sejak 2024";
    try {
      if (rawCreatedAt != null) {
        joinDate = "Member sejak ${rawCreatedAt.toDate().year}";
      }
    } catch (_) {}
    final int followersCount = _userProfile?['followersCount'] ?? 0;
    final String statsFollowers = "$followersCount Followers";
    final int listingCount = _userProfile?['totalTransactions'] ?? 0;
    final String statsListings = widget.listingCount != null ? "${widget.listingCount} Active Listings" : "$listingCount+ Transactions";
    final String aboutMeText = _userProfile?['aboutMe'] as String? ?? "Belum ada informasi profil.";
    
    final String? avatarUrl = () {
      final profile = _userProfile?['profilePhotoUrl'] as String?;
      if (profile != null && profile.trim().isNotEmpty) return profile;
      final selfie = _userProfile?['selfiePhotoUrl'] as String?;
      if (selfie != null && selfie.trim().isNotEmpty) return selfie;
      return null;
    }();
    final ImageProvider effectiveAvatar = avatarUrl != null 
        ? NetworkImage(avatarUrl) as ImageProvider 
        : (widget.avatarImage ?? const AssetImage("assets/images/profile_user.png"));

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF), // Cream background
      body: StreamBuilder<List<ItemModel>>(
        stream: _itemsStream,
        builder: (context, snapshot) {
          final items = snapshot.data ?? [];
          
          final List<ItemModel> filteredProducts = items.where((product) {
            final matchesCategory = _selectedCategory == "All" || product.categoryName == _selectedCategory;
            final matchesSearch = _searchQuery.isEmpty || product.name.toLowerCase().contains(_searchQuery);
            return matchesCategory && matchesSearch;
          }).toList();

          return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF012D1D),
            pinned: false,
            automaticallyImplyLeading: false,
            expandedHeight: 270,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SafeArea(
                    bottom: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
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
                        GestureDetector(
                          onTap: () {
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
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                            Positioned(
                              bottom: -6,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8BD00),
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
                                        displayRating,
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
                  const SizedBox(height: 10),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      children: [
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
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RoomChatScreen(
                                    partnerId: widget.ownerId ?? "unknown_user",
                                    partnerName: displayName,
                                    itemId: "profile_chat",
                                    itemName: "Diskusi Profil",
                                    itemPhotoUrl: "",
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
                  const SizedBox(height: 10),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              color: const Color(0xFF414844).withValues(alpha: 0.2),
                            ),

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
                                                ownerName: displayName,
                                                ownerId: _targetOwnerId,
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
                                SizedBox(
                                  height: 135,
                                  child: StreamBuilder<List<Map<String, dynamic>>>(
                                    stream: _reviewsStream,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return const Center(child: CircularProgressIndicator(color: Color(0xFF012D1D)));
                                      }
                                      final reviews = snapshot.data ?? [];
                                      if (reviews.isEmpty) {
                                        return const Center(
                                          child: Text(
                                            "Belum ada ulasan.",
                                            style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.grey),
                                          ),
                                        );
                                      }
                                      return ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        physics: const BouncingScrollPhysics(),
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                        itemCount: reviews.length,
                                        separatorBuilder: (context, index) => const SizedBox(width: 12),
                                        itemBuilder: (context, index) {
                                          final r = reviews[index];
                                          final dateObj = r['createdAt']?.toDate() ?? DateTime.now();
                                          final dateStr = "${dateObj.day}-${dateObj.month}-${dateObj.year}";
                                          return _buildReviewCard(
                                            r['fromUserName'] ?? "Anonim",
                                            dateStr,
                                            r['score'] ?? 5,
                                            r['comment'] ?? "",
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),

                            Container(
                              height: 0.5,
                              margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                              color: const Color(0xFF414844).withValues(alpha: 0.2),
                            ),

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
                    ),

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
                                    final itemModel = filteredProducts[index];
                                    final product = ProductData(
                                      id: itemModel.id,
                                      name: itemModel.name,
                                      price: itemModel.formattedPrice,
                                      rating: itemModel.ownerRating > 0 ? itemModel.ownerRating.toDouble() : 4.5,
                                      image: itemModel.primaryPhoto,
                                      isLocalAsset: !itemModel.primaryPhoto.startsWith('http'),
                                      originalItem: itemModel,
                                    );
                                    return SubtleFadeIn(
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => ItemDetailScreen(
                                                item: itemModel,
                                                itemId: itemModel.id,
                                                itemName: product.name,
                                                pricePerHour: itemModel.pricePerHour,
                                                sellerLocation: _userProfile?['location'] as String? ?? "Lokasi tidak tersedia",
                                                imagePath: product.image,
                                                isLocalAsset: product.isLocalAsset,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ProductCard(
                                          product: product,
                                          onMorePressed: () {
                                            final isOwnItem = itemModel.ownerId == FirebaseAuth.instance.currentUser?.uid;
                                            showProductMoreSheet(
                                              context: context,
                                              product: product,
                                              onFavoritePressed: () {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      '${product.name} disimpan ke Favorit!',
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
                                                      searchQuery: product.name,
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
                                                 final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                                 final reportedId = _targetOwnerId;
                                                 
                                                 if (reportedId.isEmpty) {
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                     const SnackBar(
                                                       content: Text('Informasi pemilik tidak tersedia untuk dilaporkan.', style: TextStyle(fontFamily: 'Poppins')),
                                                       backgroundColor: Color(0xFFE33629),
                                                       behavior: SnackBarBehavior.floating,
                                                     ),
                                                   );
                                                   return;
                                                 }
                                                 
                                                 if (currentUserId == reportedId) {
                                                   ScaffoldMessenger.of(context).showSnackBar(
                                                     const SnackBar(
                                                       content: Text('Anda tidak bisa melaporkan barang Anda sendiri.', style: TextStyle(fontFamily: 'Poppins')),
                                                       backgroundColor: Color(0xFFE33629),
                                                       behavior: SnackBarBehavior.floating,
                                                     ),
                                                   );
                                                   return;
                                                 }

                                                 showReportDialog(
                                                   context,
                                                   reportedId: reportedId,
                                                   itemId: itemModel.id,
                                                   itemName: product.name,
                                                 );
                                               },
                                              onEditPressed: isOwnItem
                                                  ? () {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => AddProductScreen(
                                                            editItem: itemModel,
                                                          ),
                                                        ),
                                                      ).then((_) {
                                                        _loadProfile();
                                                      });
                                                    }
                                                  : null,
                                              onDeletePressed: isOwnItem
                                                  ? () async {
                                                      final confirm = await showDialog<bool>(
                                                        context: context,
                                                        builder: (context) => AlertDialog(
                                                          backgroundColor: const Color(0xFFFFF8EF),
                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                                          title: const Text('Hapus Barang?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                                                          content: const Text('Apakah Anda yakin ingin menghapus barang ini? Status barang akan diarsipkan.', style: TextStyle(fontFamily: 'Poppins')),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () => Navigator.pop(context, false),
                                                              child: const Text('Batal', style: TextStyle(color: Color(0xFF585D59))),
                                                            ),
                                                            ElevatedButton(
                                                              style: ElevatedButton.styleFrom(
                                                                backgroundColor: const Color(0xFFE33629),
                                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                              ),
                                                              onPressed: () => Navigator.pop(context, true),
                                                              child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                                                            ),
                                                          ],
                                                        ),
                                                      );

                                                      if (confirm != true || !mounted) return;

                                                      setState(() => _isLoadingProfile = true);
                                                      try {
                                                        final token = await const AuthSessionService().getValidIdToken();
                                                        final response = await http.delete(
                                                          Uri.parse('${ApiConfig.baseUrl}/items/${itemModel.id}'),
                                                          headers: {
                                                            'Authorization': 'Bearer $token',
                                                          },
                                                        );
                                                        if (response.statusCode == 200) {
                                                          if (!context.mounted) return;
                                                          showAppSuccessSnack(context, 'Barang berhasil dihapus!');
                                                          _loadProfile();
                                                        } else {
                                                          if (!context.mounted) return;
                                                          showAppErrorSnack(context, 'Gagal menghapus barang.');
                                                        }
                                                      } catch (e) {
                                                        if (!context.mounted) return;
                                                        showAppErrorSnack(context, 'Terjadi kesalahan: $e');
                                                      } finally {
                                                        if (mounted) {
                                                          setState(() => _isLoadingProfile = false);
                                                        }
                                                      }
                                                    }
                                                  : null,
                                            );
                                          },
                                        ),
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
          );
        },
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
