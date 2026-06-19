import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:async';
import 'data/models/item_model.dart';
import 'data/repositories/item_repository.dart';
import 'models/category_model.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'widgets/product_more_sheet.dart';
import 'item_detail_screen.dart';
import 'favorite_service.dart';
import 'widgets/report_dialog.dart';
import 'widgets/subtle_fade_in.dart';
import 'widgets/pressable_scale.dart';
import 'widgets/skeleton_loader.dart';
import 'widgets/custom_app_bar.dart';

enum CategorySortOption { relevance, lowestPrice, highestPrice, highestRating }

class CategoryDetailScreen extends StatefulWidget {
  final CategoryModel category;

  const CategoryDetailScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final ItemRepository _itemRepo = ItemRepository();
  StreamSubscription<List<ItemModel>>? _itemsSub;
  
  List<ItemModel> _allItems = [];
  List<ItemModel> _results = [];
  bool _isLoading = true;
  CategorySortOption _currentSort = CategorySortOption.relevance;

  @override
  void initState() {
    super.initState();
    _itemsSub = _itemRepo.watchSearchableItems().listen((items) {
      if (!mounted) return;
      setState(() {
        // Filter by categoryName or categoryId matching the code/name from API
        // Typically code or category string is stored in the item's categoryId or categoryName.
        // Let's filter loosely by comparing against both.
        _allItems = items.where((item) {
          final catId = item.categoryId.toLowerCase();
          final catName = item.categoryName.toLowerCase();
          final apiCode = widget.category.code.toLowerCase();
          final apiCat = widget.category.category.toLowerCase();
          return catId == apiCode || catId == apiCat || catName == apiCat || catName == apiCode;
        }).toList();
        _isLoading = false;
        _applySort();
      });
    });
  }

  void _applySort() {
    final sorted = List<ItemModel>.from(_allItems);
    if (_currentSort == CategorySortOption.lowestPrice) {
      sorted.sort((a, b) => a.pricePerHour.compareTo(b.pricePerHour));
    } else if (_currentSort == CategorySortOption.highestPrice) {
      sorted.sort((a, b) => b.pricePerHour.compareTo(a.pricePerHour));
    } else if (_currentSort == CategorySortOption.highestRating) {
      sorted.sort((a, b) => b.ownerRating.compareTo(a.ownerRating));
    }
    setState(() {
      _results = sorted;
    });
  }

  @override
  void dispose() {
    _itemsSub?.cancel();
    super.dispose();
  }

  ProductData _toProductData(ItemModel item) => ProductData(
        id: item.id,
        name: item.name,
        price: item.formattedPricePerDay,
        rating: item.ownerRating > 0 ? item.ownerRating.toDouble() : 4.5,
        image: item.primaryPhoto,
        isLocalAsset: !item.primaryPhoto.startsWith('http'),
        originalItem: item,
      );

  void _navigateToDetail(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          itemId: item.id,
          itemName: item.name,
          pricePerHour: item.pricePerHour,
          imagePath: item.primaryPhoto,
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
      onSimilarPressed: () {},
      onNotInterestedPressed: () {
        setState(() {
          _results.removeWhere((i) => i.id == item.id);
        });
      },
      onReportPressed: () {
        if (item.ownerId.isEmpty) return;
        showReportDialog(
          context,
          reportedId: item.ownerId,
          itemId: item.id,
          itemName: item.name,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String displayCategory = widget.category.category;
    if (displayCategory == "Komputer & Aksesoris") {
      displayCategory = "Komp & Aksesoris";
    } else {
      final upper = displayCategory.toUpperCase();
      if (upper == 'OUTFIT') {
        displayCategory = "Pakaian";
      } else if (upper == 'SPORTS') {
        displayCategory = "Olahraga";
      } else if (upper == 'ALAT CAMPING' || upper == 'CAMP TOOLS' || upper == 'CAMPING TOOLS') {
        displayCategory = "Alat Kemah";
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: CustomAppBar(
        title: displayCategory,
      ),
      body: _isLoading
          ? GridView.builder(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 16.0,
                right: 16.0,
                bottom: 16.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
                childAspectRatio: 0.65,
              ),
              itemCount: 4,
              itemBuilder: (context, index) => const ProductCardSkeleton(),
            )
          : _results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.category_rounded, size: 56, color: const Color(0xFF012D1D).withValues(alpha: 0.25)),
                      const SizedBox(height: 12),
                      Text(
                        'Tidak ada produk di kategori $displayCategory',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF414844),
                        ),
                      ),
                    ],
                  ),
                )
              : CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                          left: 24,
                          right: 24,
                          bottom: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hasil: ${_results.length} produk',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF012D1D),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFFFF),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFF012D1D).withValues(alpha: 0.12),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<CategorySortOption>(
                                  value: _currentSort,
                                  icon: const Padding(
                                    padding: EdgeInsets.only(left: 6.0),
                                    child: Icon(Icons.sort_rounded, color: Color(0xFF012D1D), size: 16),
                                  ),
                                  dropdownColor: const Color(0xFFFFFFFF),
                                  borderRadius: BorderRadius.circular(12),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Color(0xFF012D1D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  onChanged: (CategorySortOption? newValue) {
                                    if (newValue != null) {
                                      setState(() {
                                        _currentSort = newValue;
                                        _applySort();
                                      });
                                    }
                                  },
                                  items: const [
                                    DropdownMenuItem(
                                      value: CategorySortOption.relevance,
                                      child: Text("Paling Relevan"),
                                    ),
                                    DropdownMenuItem(
                                      value: CategorySortOption.lowestPrice,
                                      child: Text("Harga Terendah"),
                                    ),
                                    DropdownMenuItem(
                                      value: CategorySortOption.highestPrice,
                                      child: Text("Harga Tertinggi"),
                                    ),
                                    DropdownMenuItem(
                                      value: CategorySortOption.highestRating,
                                      child: Text("Rating Tertinggi"),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.only(
                        left: 16.0,
                        right: 16.0,
                        bottom: 24.0,
                      ),
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
                            return SubtleFadeIn(
                              delay: Duration(milliseconds: index * 45),
                              child: PressableScale(
                                onTap: () => _navigateToDetail(item),
                                child: ProductCard(
                                  product: product,
                                  onMorePressed: () => _showProductOptions(context, item, product),
                                ),
                              ),
                            );
                          },
                          childCount: _results.length,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
