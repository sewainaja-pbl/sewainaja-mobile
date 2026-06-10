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
  
  List<ItemModel> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _itemsSub = _itemRepo.watchSearchableItems().listen((items) {
      if (!mounted) return;
      setState(() {
        // Filter by categoryName or categoryId matching the code/name from API
        // Typically code or category string is stored in the item's categoryId or categoryName.
        // Let's filter loosely by comparing against both.
        _results = items.where((item) {
          final catId = item.categoryId.toLowerCase();
          final catName = item.categoryName.toLowerCase();
          final apiCode = widget.category.code.toLowerCase();
          final apiCat = widget.category.category.toLowerCase();
          return catId == apiCode || catId == apiCat || catName == apiCat || catName == apiCode;
        }).toList();
        _isLoading = false;
      });
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
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4).withValues(alpha: 0.6),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 60,
        titleSpacing: 24,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
        title: Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF012D1D),
                  size: 28,
                ),
              ),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.category.category,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 28),
            ],
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
      body: _isLoading
          ? GridView.builder(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 60 + 12,
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
                        'Tidak ada produk di kategori ${widget.category.category}',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Color(0xFF414844),
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 60 + 12,
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
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
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
                ),
    );
  }
}
