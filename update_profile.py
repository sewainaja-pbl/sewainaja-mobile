import re

with open('lib/profile_view_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add imports
content = content.replace(
    "import 'widgets/report_dialog.dart';",
    "import 'widgets/report_dialog.dart';\nimport 'data/repositories/user_repository.dart';\nimport 'data/repositories/rating_repository.dart';\nimport 'data/repositories/item_repository.dart';\nimport 'data/models/item_model.dart';"
)

# Update state variables
state_old = '''  final List<String> _categories = [
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

  Future<void> _loadItems() async {'''

state_new = '''  final List<String> _categories = [
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
    _loadProfile();
    if (_targetOwnerId.isNotEmpty) {
      _itemsStream = _itemRepo.watchItemsByOwner(_targetOwnerId);
      _reviewsStream = _ratingRepo.watchOwnerReviews(_targetOwnerId);
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
    final profile = await _userRepo.getUserProfile(_targetOwnerId);
    if (mounted) {
      setState(() {
        _userProfile = profile;
        _isLoadingProfile = false;
      });
    }
  }

  // Obsolete local items loading (commented out/removed)
  Future<void> _loadItems() async {'''

content = content.replace(state_old, state_new)

# In build method:
build_old = '''  @override
  Widget build(BuildContext context) {
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
      backgroundColor: const Color(0xFFFFF8EF), // Cream background
      body: CustomScrollView('''

build_new = '''  @override
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
    
    final joinDate = "Member since 2010"; // Keep dummy for now
    final String statsFollowers = "103 Followers"; // dummy
    final int listingCount = _userProfile?['totalTransactions'] ?? 20;
    final String statsListings = widget.listingCount != null ? "${widget.listingCount} Active Listings" : "$listingCount+ Transactions";
    final String aboutMeText = "Passionate gadget & tools enthusiast. I specialize in premium and well-maintained items...";
    
    final avatarUrl = _userProfile?['ktpPhotoUrl'] ?? _userProfile?['selfiePhotoUrl'];
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

          return CustomScrollView('''

content = content.replace(build_old, build_new)

# Rating replace
content = content.replace(
    '''widget.rating ?? "4.3",''',
    '''displayRating,'''
)

# Replace reviews slider
reviews_old = '''                                // Review Cards Slider
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
                                ),'''

reviews_new = '''                                // Review Cards Slider
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
                                ),'''

content = content.replace(reviews_old, reviews_new)

# Replace Grid view items mapping
grid_old = '''                                  (context, index) {
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
                                        child: ProductCard(
                                          product: product,
                                          onMorePressed: () {
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
                                                 final reportedId = widget.ownerId ?? '';
                                                 
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
                                                   itemId: productMap["id"]?.toString() ?? "local_or_dummy_item",
                                                   itemName: product.name,
                                                 );
                                               },
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },'''

grid_new = '''                                  (context, index) {
                                    final itemModel = filteredProducts[index];
                                    final product = ProductData(
                                      name: itemModel.name,
                                      price: itemModel.formattedPrice,
                                      image: itemModel.primaryPhoto,
                                      rating: itemModel.ownerRating > 0 ? itemModel.ownerRating : 4.5,
                                      isLocalAsset: !itemModel.primaryPhoto.startsWith('http'),
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
                                                pricePerHour: itemModel.pricePerHour,
                                                sellerLocation: "Tembalang, Banyumanik", // Dummy, bisa diambil dari itemModel address
                                                imagePath: product.image,
                                                isLocalAsset: product.isLocalAsset,
                                              ),
                                            ),
                                          );
                                        },
                                        child: ProductCard(
                                          product: product,
                                          onMorePressed: () {
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
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },'''

content = content.replace(grid_old, grid_new)

# Add closing tag for StreamBuilder
content = content.replace(
    '''// Grid bottom padding spacer
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
        ],
      ),
    );
  }''',
    '''// Grid bottom padding spacer
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 40),
                      ),
            ],
          );
        },
      ),
    );
  }'''
)

with open('lib/profile_view_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
