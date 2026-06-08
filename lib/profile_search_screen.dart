import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'widgets/subtle_fade_in.dart';
import 'data/models/item_model.dart';
import 'item_detail_screen.dart';

class ProfileSearchScreen extends StatefulWidget {
  final String ownerName;
  final List<Map<String, dynamic>> ownerProducts;

  const ProfileSearchScreen({
    super.key,
    required this.ownerName,
    required this.ownerProducts,
  });

  @override
  State<ProfileSearchScreen> createState() => _ProfileSearchScreenState();
}

class _ProfileSearchScreenState extends State<ProfileSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  List<Map<String, dynamic>> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    // Default to show all products initially or empty
    _filteredProducts = widget.ownerProducts;
    _searchController.addListener(_onSearchChanged);
    
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      _query = query;
      if (query.isEmpty) {
        _filteredProducts = widget.ownerProducts;
      } else {
        _filteredProducts = widget.ownerProducts
            .where((p) => p["name"].toString().toLowerCase().contains(query))
            .toList();
      }
    });
  }

  void _navigateToDetail(Map<String, dynamic> productMap) {
    ItemModel? lightweightItem;
    try {
      double parsedPrice = (productMap["price"] as num).toDouble();
      String unit = "Hari"; // Assume dummy products are daily
      double computedPricePerHour = parsedPrice / 24;
      
      lightweightItem = ItemModel(
        id: productMap['id']?.toString() ?? '',
        ownerId: '',
        ownerName: widget.ownerName,
        ownerRating: 4.8,
        categoryId: '',
        categoryName: '',
        name: productMap['name'],
        description: '',
        pricePerHour: computedPricePerHour,
        price: parsedPrice,
        priceUnit: unit,
        status: 'available',
        condition: 'fair',
        photos: [productMap['image']],
      );
    } catch (_) {}

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          itemName: productMap["name"],
          sellerLocation: "Tembalang, Banyumanik",
          imagePath: productMap["image"],
          item: lightweightItem,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF8EF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF012D1D).withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            textAlignVertical: TextAlignVertical.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF012D1D),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: InputBorder.none,
              hintText: "Cari barang di toko ${widget.ownerName}...",
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: const Color(0xFF012D1D).withValues(alpha: 0.4),
              ),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Color(0xFF012D1D)),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header showing search summary
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              _query.isEmpty
                  ? "Semua Barang (${_filteredProducts.length})"
                  : "Hasil pencarian untuk \"$_query\" (${_filteredProducts.length})",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF012D1D).withValues(alpha: 0.6),
              ),
            ),
          ),
          
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: FadeIn(
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: const Color(0xFF012D1D).withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Barang tidak ditemukan di profil ini",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF012D1D).withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Coba kata kunci lain atau periksa ejaan",
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              color: const Color(0xFF012D1D).withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredProducts.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final pMap = _filteredProducts[index];
                      final product = ProductData(
                        name: pMap["name"],
                        price: "Rp. ${pMap["price"].toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}",
                        image: pMap["image"],
                        rating: 4.5,
                      );
                      
                      return SubtleFadeIn(
                        child: GestureDetector(
                          onTap: () => _navigateToDetail(pMap),
                          child: ProductCard(
                            product: product,
                            isHorizontal: true,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
