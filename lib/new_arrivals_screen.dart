import 'dart:ui';
import 'package:flutter/material.dart';
import 'data/models/item_model.dart';
import 'data/repositories/item_repository.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'widgets/product_more_sheet.dart';
import 'search_result_screen.dart';
import 'item_detail_screen.dart';
import 'widgets/report_dialog.dart';
import 'widgets/subtle_fade_in.dart';
import 'widgets/pressable_scale.dart';
import 'app_feedback.dart';
import 'widgets/custom_app_bar.dart';

class NewArrivalsScreen extends StatelessWidget {
  const NewArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ItemRepository itemRepo = ItemRepository();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      extendBodyBehindAppBar: true,
      appBar: const CustomAppBar(
        title: 'Terbaru',
      ),
      body: StreamBuilder<List<ItemModel>>(
        stream: itemRepo.watchAllNewArrivals(),
        builder: (context, snapshot) {
          // Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingGrid(context);
          }

          // Error state
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          // Empty state
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final items = snapshot.data!;

          return CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 10,
                  left: 10.0,
                  right: 10.0,
                  bottom: 10.0,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10.0,
                    mainAxisSpacing: 10.0,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = items[index];
                      final product = ProductData(
                        id: item.id,
                        name: item.name,
                        price: item.formattedPrice,
                        rating: item.ownerRating > 0 ? item.ownerRating.toDouble() : 4.5,
                        image: item.primaryPhoto,
                        isLocalAsset: !item.primaryPhoto.startsWith('http'),
                        originalItem: item,
                      );
                      return SubtleFadeIn(
                        delay: Duration(milliseconds: index * 45),
                        child: PressableScale(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailScreen(
                                itemId: item.id,
                                item: item,
                                itemName: item.name,
                                pricePerHour: item.pricePerHour,
                                imagePath: item.primaryPhoto,
                              ),
                            ),
                          ),
                          child: ProductCard(
                            product: product,
                            onMorePressed: () {
                              showProductMoreSheet(
                                context: context,
                                product: product,
                                onFavoritePressed: () {
                                  showAppSuccessSnack(
                                    context,
                                    '\${item.name} disimpan ke Favorit!',
                                  );
                                },
                                onSimilarPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SearchResultScreen(
                                        searchQuery: item.name,
                                      ),
                                    ),
                                  );
                                },
                                onNotInterestedPressed: () {
                                  showAppSuccessSnack(
                                    context,
                                    'Rekomendasi disesuaikan. Kami akan mengurangi rekomendasi serupa.',
                                  );
                                },
                                onReportPressed: () {
                                  if (item.ownerId.isEmpty) {
                                    showAppErrorSnack(context, 'Data pemilik tidak ditemukan.');
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
                            },
                          ),
                        ),
                      );
                    },
                    childCount: items.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10.0,
        right: 10.0,
        bottom: 10.0,
      ),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10.0,
        mainAxisSpacing: 10.0,
        childAspectRatio: 0.65,
      ),
      itemCount: 6,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: const Color(0xFF012D1D).withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada barang baru',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF414844),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Barang terbaru akan muncul di sini',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: const Color(0xFF414844).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: const Color(0xFF012D1D).withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat data',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF414844),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Periksa koneksi internet kamu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                color: const Color(0xFF414844).withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer card placeholder untuk loading state.
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Color.lerp(
            const Color(0xFFE8E4DC),
            const Color(0xFFF5F1E8),
            _anim.value,
          ),
        ),
      ),
    );
  }
}
