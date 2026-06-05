import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'data/models/item_model.dart';
import 'data/repositories/item_repository.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'widgets/product_more_sheet.dart';
import 'favorite_service.dart';
import 'item_detail_screen.dart';
import 'widgets/report_dialog.dart';

enum SortOption { relevance, lowestPrice, highestPrice, highestRating }

class SearchResultScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultScreen({
    super.key,
    required this.searchQuery,
  });

  @override
  State<SearchResultScreen> createState() => _SearchResultScreenState();
}

class _SearchResultScreenState extends State<SearchResultScreen> {
  late TextEditingController _searchController;
  final ItemRepository _itemRepo = ItemRepository();
  StreamSubscription<List<ItemModel>>? _itemsSub;
  
  List<ItemModel> _allItems = [];
  List<ItemModel> _results = [];
  bool _isLoading = true;
  String _currentQuery = '';
  SortOption _currentSort = SortOption.relevance;

  static const double _fuzzyThreshold = 0.4;

  @override
  void initState() {
    super.initState();
    _currentQuery = widget.searchQuery;
    _searchController = TextEditingController(text: _currentQuery);

    _itemsSub = _itemRepo.watchSearchableItems().listen((items) {
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _isLoading = false;
        _applyFilter();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _itemsSub?.cancel();
    super.dispose();
  }

  void _applyFilter() {
    final raw = _currentQuery.trim();
    if (raw.isEmpty) {
      setState(() => _results = []);
      return;
    }

    final fuse = Fuzzy<ItemModel>(
      _allItems,
      options: FuzzyOptions<ItemModel>(
        keys: [
          WeightedKey<ItemModel>(
            name: 'name',
            getter: (item) => item.name,
            weight: 1,
          ),
        ],
        threshold: _fuzzyThreshold,
        isCaseSensitive: false,
      ),
    );

    final filtered = fuse.search(raw).map((r) => r.item).toList();

    // Terapkan sorting sesuai opsi yang dipilih
    if (_currentSort == SortOption.lowestPrice) {
      filtered.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    } else if (_currentSort == SortOption.highestPrice) {
      filtered.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
    } else if (_currentSort == SortOption.highestRating) {
      filtered.sort((a, b) => b.ownerRating.compareTo(a.ownerRating));
    }

    setState(() => _results = filtered);
  }

  void _submitSearch(String value) {
    if (value.trim().isEmpty) return;
    setState(() {
      _currentQuery = value.trim();
      _isLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() => _isLoading = false);
        _applyFilter();
      }
    });
  }

  ProductData _toProductData(ItemModel item) => ProductData(
        id: item.id,
        name: item.name,
        price: item.formattedPricePerHour,
        rating: item.ownerRating > 0
            ? item.ownerRating.toStringAsFixed(1)
            : '—',
        image: item.primaryPhoto,
      );

  void _navigateToDetail(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          itemName: item.name,
          pricePerHour: item.pricePerHour,
          imagePath: item.primaryPhoto,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4).withValues(alpha: 0.6),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 24,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF012D1D),
                  size: 28,
                ),
              ),
              const Spacer(),
              const Text(
                'Search',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF012D1D),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 28),
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
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Search Input Box
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 80 + 16,
                  left: 24,
                  right: 24,
                  bottom: 16,
                ),
                sliver: SliverToBoxAdapter(
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
                      textInputAction: TextInputAction.search,
                      onSubmitted: _submitSearch,
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF012D1D),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF012D1D), size: 20),
                          onPressed: () {
                            _searchController.clear();
                            _submitSearch('');
                          },
                        ),
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
                ),
              ),

              // Sort Dropdown Header
              if (!_isLoading && _results.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hasil: ${_results.length} produk',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF012D1D).withValues(alpha: 0.1)),
                          ),
                          child: DropdownButton<SortOption>(
                            value: _currentSort,
                            icon: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.sort, color: Color(0xFF012D1D), size: 18),
                            ),
                            elevation: 16,
                            style: const TextStyle(
                              fontFamily: 'Poppins', 
                              color: Color(0xFF012D1D), 
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            underline: Container(height: 0),
                            onChanged: (SortOption? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _currentSort = newValue;
                                  _applyFilter();
                                });
                              }
                            },
                            items: const [
                              DropdownMenuItem(value: SortOption.relevance, child: Text("Paling Relevan")),
                              DropdownMenuItem(value: SortOption.lowestPrice, child: Text("Harga Terendah")),
                              DropdownMenuItem(value: SortOption.highestPrice, child: Text("Harga Tertinggi")),
                              DropdownMenuItem(value: SortOption.highestRating, child: Text("Rating Tertinggi")),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading / Empty / Results Data
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF012D1D))),
                )
              else if (_results.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded, size: 56, color: const Color(0xFF012D1D).withValues(alpha: 0.25)),
                        const SizedBox(height: 12),
                        Text(
                          'Tidak ada hasil untuk "$_currentQuery"',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            color: Color(0xFF414844),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120), // Memberi ruang navbar melayang di bawah
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = _results[index];
                        final product = _toProductData(item);
                        return GestureDetector(
                          onTap: () => _navigateToDetail(item),
                          child: ProductCard(
                            product: product,
                            onMorePressed: () => _showProductOptions(context, item, product),
                          ),
                        );
                      },
                      childCount: _results.length,
                    ),
                  ),
                ),
            ],
          ),

          // CUSTOM FLOATING BOTTOM NAVBAR
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: Container(
                height: 75,
                margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      index: 0,
                      activeIcon: Icons.home_rounded,
                      inactiveIcon: Icons.home_outlined,
                    ),
                    _buildNavItem(
                      index: 1,
                      activeIcon: Icons.grid_view_rounded,
                      inactiveIcon: Icons.grid_view_outlined,
                    ),
                    _buildNavItem(
                      index: 2,
                      activeIcon: Icons.add_box_rounded,
                      inactiveIcon: Icons.add_box_outlined,
                    ),
                    _buildNavItem(
                      index: 3,
                      activeIcon: Icons.chat_bubble_rounded,
                      inactiveIcon: Icons.chat_bubble_outline_rounded,
                    ),
                    _buildNavItem(
                      index: 4,
                      activeIcon: Icons.person_rounded,
                      inactiveIcon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        setState(() {
          _currentQuery = item.name;
          _searchController.text = item.name;
          _applyFilter();
        });
      },
      onNotInterestedPressed: () {
        setState(() {
          _results.removeWhere((i) => i.id == item.id);
        });
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

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    // Di search result screen tidak ada index navbar yang aktif
    return GestureDetector(
      onTap: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 55,
        height: 55,
        decoration: const BoxDecoration(
          color: Color(0xFF1B4332),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            inactiveIcon,
            color: const Color(0xFFFFF8EF),
            size: 24,
          ),
        ),
      ),
    );
  }
}
