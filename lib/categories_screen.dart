import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'presentation/controllers/category_controller.dart';
import 'category_detail_screen.dart';
import 'models/category_model.dart';
import 'widgets/subtle_fade_in.dart';
import 'widgets/pressable_scale.dart';
import 'widgets/skeleton_loader.dart';
import 'widgets/custom_app_bar.dart';

class CategoriesScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const CategoriesScreen({super.key, this.onBack});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = Provider.of<CategoryController>(context, listen: false);
      if (controller.categories.isEmpty) {
        controller.fetchCategories();
      }
    });
  }

  void _handleBack(BuildContext context) {
    final didPop = Navigator.of(context).maybePop();
    didPop.then((popped) {
      if (!popped && widget.onBack != null) {
        widget.onBack!();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // main_bg
      extendBodyBehindAppBar: false,
      appBar: CustomAppBar(
        title: 'Categories',
        onBack: () => _handleBack(context),
      ),
      body: Consumer<CategoryController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return GridView.builder(
              padding: const EdgeInsets.only(
                top: 16.0,
                left: 20.0,
                right: 20.0,
                bottom: 120.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => const CategoryCardSkeleton(),
            );
          }

          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFE33629), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    controller.errorMessage!,
                    style: const TextStyle(fontFamily: 'Poppins', color: Color(0xFF012D1D)),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => controller.fetchCategories(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF012D1D),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Coba Lagi', style: TextStyle(fontFamily: 'Poppins')),
                  )
                ],
              ),
            );
          }

          final categories = controller.categories;

          if (categories.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.category_outlined, size: 56, color: const Color(0xFF012D1D).withValues(alpha: 0.25)),
                  const SizedBox(height: 12),
                  const Text(
                    'Belum ada kategori.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Color(0xFF414844),
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.only(
              top: 16.0,
              left: 20.0,
              right: 20.0,
              bottom: 120.0,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7, // Disesuaikan agar card lebih tinggi (seperti foto)
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];

              const colors = [
                Color(0xFF00FFE1), // Teal
                Color(0xFFE6D399), // Gold
                Color(0xFF8A38F5), // Purple
                Color(0xFF22C23A), // Green
                Color(0xFFF59D38), // Orange
                Color(0xFFF53838), // Red
              ];
              
              final color = colors[index % colors.length];

              return SubtleFadeIn(
                delay: Duration(milliseconds: index * 40),
                child: _CategoryCard(
                  title: cat.category,
                  fontSize: 32, // Ukuran teks diperkecil agar kata panjang seperti KAMERA & LENSA tidak terpotong
                  photoUrl: cat.photoUrl,
                  gradientOverlay: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      color, 
                      color.withValues(alpha: 0.5), 
                      color.withValues(alpha: 0.0), 
                    ],
                    stops: const [0.0, 0.2, 1.0],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CategoryDetailScreen(category: cat),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final double fontSize;
  final String? photoUrl;
  final Gradient? gradientOverlay;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.fontSize,
    this.photoUrl,
    this.gradientOverlay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9), // card_placeholder
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              if (photoUrl != null && photoUrl!.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: photoUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 250, // Optimize memory for category card thumbnails
                    placeholder: (context, url) => const ShimmerContainer(
                      width: double.infinity,
                      height: double.infinity,
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
                ),
              // Linear Gradient Overlay
              if (gradientOverlay != null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradientOverlay,
                    ),
                  ),
                ),
              // Default dark overlay untuk teks putih jika tidak ada gradient
              if (gradientOverlay == null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BebasNeue',
                      fontSize: fontSize,
                      color: const Color(0xFFFFFFFF),
                      height: 1.1,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
