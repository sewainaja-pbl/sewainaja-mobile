import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'data/models/item_model.dart';
import 'data/repositories/item_repository.dart';
import 'item_detail_screen.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'widgets/subtle_fade_in.dart';

// ---------------------------------------------------------------------------
// Suggestions list — tetap dipertahankan untuk saat query kosong
// ---------------------------------------------------------------------------
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
// SearchSheet — rendered di dalam HomeScreen's Stack
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
  // ── Animation ──────────────────────────────────────────────────────────────
  late final AnimationController _sheetAnim;
  late final Animation<Offset> _sheetSlide;

  // ── Search state ───────────────────────────────────────────────────────────
  String _query = '';
  List<ItemModel> _results = [];

  // ── Firestore data ─────────────────────────────────────────────────────────
  final ItemRepository _itemRepo = ItemRepository();
  List<ItemModel> _allItems = [];
  StreamSubscription<List<ItemModel>>? _itemsSub;
  bool _isLoadingItems = true;

  // ── Fuzzy options ──────────────────────────────────────────────────────────
  static const double _fuzzyThreshold = 0.4;

  @override
  void initState() {
    super.initState();

    // Sheet slides up from bottom
    _sheetAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _sheetSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _sheetAnim, curve: Curves.easeOutCubic));

    _sheetAnim.forward();

    // Subscribe ke Firestore stream
    _itemsSub = _itemRepo.watchSearchableItems().listen((items) {
      if (!mounted) return;
      setState(() {
        _allItems = items;
        _isLoadingItems = false;
        // Re-filter jika ada query aktif
        if (_query.isNotEmpty) _applyFilter();
      });
    });

    // Listen ke shared controller
    widget.controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onQueryChanged);
    _sheetAnim.dispose();
    _itemsSub?.cancel();
    super.dispose();
  }

  // ── Query change handler ───────────────────────────────────────────────────
  void _onQueryChanged() {
    final raw = widget.controller.text.trim();
    setState(() {
      _query = raw.toLowerCase();
    });
    _applyFilter();
  }

  // ── Core filter logic — Fuzzy only ─────────────────────────────────────────
  void _applyFilter() {
    final raw = widget.controller.text.trim();
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

    setState(() => _results = filtered);
  }

  // ── Convert ItemModel → ProductData (untuk ProductCard) ───────────────────
  ProductData _toProductData(ItemModel item) => ProductData(
        id: item.id,
        name: item.name,
        price: item.formattedPrice,
        rating: item.ownerRating > 0 ? item.ownerRating.toDouble() : 4.5,
        image: item.primaryPhoto,
        isLocalAsset: !item.primaryPhoto.startsWith('http'),
        originalItem: item,
      );

  // ── Close animation ────────────────────────────────────────────────────────
  Future<void> closeAsync() async {
    await _sheetAnim.reverse();
  }

  // ── Navigate to detail ─────────────────────────────────────────────────────
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

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final topOffset = MediaQuery.of(context).padding.top + 156.0;

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
                // ── Drag handle ────────────────────────────────────────────
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6C7A1).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                // ── Body: suggestions / loading / results ──────────────────
                Expanded(
                  child: _query.isEmpty
                      ? _buildSuggestions()
                      : _isLoadingItems
                          ? _buildLoadingState()
                          : _buildResults(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Suggestions (query kosong) ─────────────────────────────────────────────
  Widget _buildSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
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
                      const Icon(
                        Icons.trending_up_rounded,
                        size: 14,
                        color: Color(0xFF012D1D),
                      ),
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

  // ── Loading state ──────────────────────────────────────────────────────────
  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Color(0xFF012D1D)),
        strokeWidth: 2.5,
      ),
    );
  }

  // ── Results ────────────────────────────────────────────────────────────────
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
            const SizedBox(height: 6),
            Text(
              'Coba kata kunci yang berbeda',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: const Color(0xFF888888).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 10),
          child: Text(
            '${_results.length} hasil ditemukan',
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            physics: const BouncingScrollPhysics(),
            itemCount: _results.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _results[index];
              final product = _toProductData(item);
              return SubtleFadeIn(
                child: GestureDetector(
                  onTap: () => _navigateToDetail(item),
                  child: ProductCard(product: product, isHorizontal: true),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
