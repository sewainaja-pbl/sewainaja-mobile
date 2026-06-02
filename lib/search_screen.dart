import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'item_detail_screen.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';

// ---------------------------------------------------------------------------
// All products pool — kept here so search works independently.
// ---------------------------------------------------------------------------
final List<ProductData> _allProducts = [
  // Tech
  ProductData(name: "Vivo Y15s 8/128GB", price: "Rp.120,000", rating: "4.8(292)", image: "assets/images/handphone.jpg"),
  ProductData(name: "Realme C55 12/512GB", price: "Rp.45,000", rating: "4.8(292)", image: "assets/images/hp_realme.jpg"),
  ProductData(name: "EOS 5D Mark IV", price: "Rp.120,000", rating: "4.8(292)", image: "assets/images/camera_canon.jpg"),
  ProductData(name: "Sony FX30", price: "Rp.45,000", rating: "4.8(292)", image: "assets/images/camera_sony.jpg"),
  ProductData(name: "Asus Zenfone 12 Ultra 16/512GB", price: "Rp.120,000", rating: "4.8(292)", image: "assets/images/hp_asus.jpg"),
  ProductData(name: "Nikon Coolpix B500", price: "Rp.45,000", rating: "4.8(292)", image: "assets/images/camera_nikon.jpg"),
  // Power Tools
  ProductData(name: "Bor Listrik Cordless 12V", price: "Rp.50,000", rating: "4.8(124)", image: "assets/images/bor_listrik.png"),
  ProductData(name: "Mesin Gerinda Tangan 4-Inch", price: "Rp.45,000", rating: "4.7(88)", image: "assets/images/mesin_gerinda.png"),
  ProductData(name: "Gergaji Circular Listrik 7-Inch", price: "Rp.75,000", rating: "4.9(42)", image: "assets/images/gergaji_circular.png"),
  ProductData(name: "Obeng Listrik Cordless Mini", price: "Rp.30,000", rating: "4.6(15)", image: "assets/images/obeng_listrik.png"),
  ProductData(name: "Mesin Serut Kayu Listrik", price: "Rp.60,000", rating: "4.8(54)", image: "assets/images/mesin_serut.png"),
  ProductData(name: "Mesin Amplas Listrik", price: "Rp.35,000", rating: "4.7(29)", image: "assets/images/mesin_amplas.png"),
  // Outfit
  ProductData(name: "Kemeja Panjang Krem", price: "Rp.120,000", rating: "4.8(292)", image: "assets/images/kemeja_warna_putih.jpg"),
  ProductData(name: "Kemeja Warna Coklat", price: "Rp.45,000", rating: "4.8(292)", image: "assets/images/kemeja_lengan_panjang.jpg"),
  ProductData(name: "Jas Hitam", price: "Rp.120,000", rating: "4.8(292)", image: "assets/images/jaz_hitam.jpg"),
  ProductData(name: "Jas Abu-Abu", price: "Rp.45,000", rating: "4.8(292)", image: "assets/images/jaz_abu.jpg"),
  ProductData(name: "Celana Panjang Jeans", price: "Rp.120,000", rating: "4.8(292)", image: "assets/images/celana_jeans.jpg"),
  ProductData(name: "Celana Panjang Corduroy", price: "Rp.45,000", rating: "4.8(292)", image: "assets/images/celana.jpg"),
  // Camp Tools
  ProductData(name: "Tenda Camping Dome 4 Orang", price: "Rp.80,000", rating: "4.8(192)", image: "assets/images/tenda_camping.png"),
  ProductData(name: "Tas Carrier Outdoor 60L", price: "Rp.45,000", rating: "4.7(120)", image: "assets/images/tas_carrier.png"),
  ProductData(name: "Sleeping Bag Mummy Premium", price: "Rp.25,000", rating: "4.9(78)", image: "assets/images/sleeping_bag.png"),
  ProductData(name: "Kompor Camping Portable Gas", price: "Rp.20,000", rating: "4.8(115)", image: "assets/images/kompor_camping.png"),
  ProductData(name: "Lentera LED Camping Rechargeable", price: "Rp.15,000", rating: "4.6(43)", image: "assets/images/lentera_camping.png"),
  ProductData(name: "Matras Angin Camping Double", price: "Rp.35,000", rating: "4.8(62)", image: "assets/images/matras_camping.png"),
  // Cook
  ProductData(name: "Panci Camping Set", price: "Rp.25,000", rating: "4.9(110)", image: "assets/images/cook_category.jpg"),
  ProductData(name: "Kompor Portable", price: "Rp.30,000", rating: "4.8(250)", image: "assets/images/cook_category.jpg"),
  ProductData(name: "Set Pisau Dapur", price: "Rp.15,000", rating: "4.7(60)", image: "assets/images/cook_category.jpg"),
  ProductData(name: "Grill Pan BBQ", price: "Rp.35,000", rating: "4.9(85)", image: "assets/images/cook_category.jpg"),
  // Sports
  ProductData(name: "Sepeda Gunung MTB", price: "Rp.100,000", rating: "4.8(292)", image: "assets/images/sports_category.jpg"),
  ProductData(name: "Treadmill Elektrik", price: "Rp.150,000", rating: "4.9(120)", image: "assets/images/sports_category.jpg"),
  ProductData(name: "Raket Tenis Wilson", price: "Rp.50,000", rating: "4.7(85)", image: "assets/images/sports_category.jpg"),
  ProductData(name: "Set Stik Golf Professional", price: "Rp.200,000", rating: "4.9(30)", image: "assets/images/sports_category.jpg"),
  // New Arrivals
  ProductData(name: "Sony W830", price: "Rp.120,000", rating: 4.8, image: "assets/images/sony_camera.png"),
  ProductData(name: "Sony Dual-Sense PS5", price: "Rp.45,000", rating: 4.8, image: "assets/images/ps5_controller.png"),
  ProductData(name: "Apple Airpods Max 2", price: "Rp.45,000", rating: 4.8, image: "assets/images/airpods_max.png"),
];

const List<String> _suggestions = [
  'Kamera DSLR',
  'Tenda Camping',
  'Bor Listrik',
  'Kemeja Formal',
  'Sepeda Gunung',
  'Kompor Portable',
  'PS5 Controller',
  'Sleeping Bag',
];

// ---------------------------------------------------------------------------
// SearchSheet — rendered directly inside HomeScreen's Stack (not a new route).
// It receives the shared controller/focusNode from HomeScreen so the search
// bar in the green header stays the single source of truth for input.
// ---------------------------------------------------------------------------
class SearchSheet extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClose;

  const SearchSheet({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onClose,
  });

  @override
  State<SearchSheet> createState() => SearchSheetState();
}

class SearchSheetState extends State<SearchSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sheetAnim;
  late final Animation<Offset> _sheetSlide;

  String _query = '';
  List<ProductData> _results = [];

  @override
  void initState() {
    super.initState();

    // Sheet slides up from bottom
    _sheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),  // starts below screen
      end: Offset.zero,           // slides up into view
    ).animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic));

    _sheetAnim.forward();

    // Listen to the shared controller for query changes
    widget.controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onQueryChanged);
    _sheetAnim.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = widget.controller.text.trim().toLowerCase();
    setState(() {
      _query = q;
      _results = q.isEmpty
          ? []
          : _allProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
    });
  }

  /// Called by HomeScreen to animate the sheet sliding DOWN before removing it.
  Future<void> closeAsync() async {
    await _sheetAnim.reverse();
  }

  void _navigateToDetail(ProductData product) {
    final cleanedPrice = product.price.replaceAll(RegExp(r'[^0-9]'), '');
    final pricePerHour = double.tryParse(cleanedPrice);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ItemDetailScreen(
          itemName: product.name,
          pricePerHour: pricePerHour,
          imagePath: product.image,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    // Sheet starts just below the green header (search bar area ~140px from top)
    // so the search bar stays fully visible above the sheet.
    final topOffset = MediaQuery.of(context).padding.top + 140.0;

    return Positioned(
      top: topOffset,
      left: 0,
      right: 0,
      bottom: 0,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: SlideTransition(
          position: _sheetSlide,
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFFFFF8EF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                // ── Drag handle ───────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6C7A1).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // ── Body: suggestions or results ──────────────────────────
                Expanded(
                  child: _query.isEmpty ? _buildSuggestions() : _buildResults(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pencarian Populer',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF414844),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  widget.controller.text = s;
                  widget.controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: s.length),
                  );
                  widget.focusNode.requestFocus();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF012D1D)),
                      const SizedBox(width: 6),
                      Text(
                        s,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 56,
              color: const Color(0xFF012D1D).withValues(alpha: 0.25),
            ),
            const SizedBox(height: 12),
            Text(
              'Tidak ada hasil untuk "$_query"',
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      physics: const BouncingScrollPhysics(),
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = _results[index];
        return FadeInUp(
          duration: const Duration(milliseconds: 200),
          delay: Duration(milliseconds: 40 * index),
          child: GestureDetector(
            onTap: () => _navigateToDetail(product),
            child: ProductCard(product: product, isHorizontal: true),
          ),
        );
      },
    );
  }
}
