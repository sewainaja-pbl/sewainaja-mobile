import 'package:flutter/material.dart';
import 'categories_tech_screen.dart';
import 'categories_power_tools_screen.dart';
import 'categories_camp_tools_screen.dart';
import 'categories_outfit_screen.dart';
import 'categories_sports_screen.dart';
import 'categories_cook_screen.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // main_bg
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
              onPressed: () => Navigator.pop(context),
              iconSize: 24,
            ),
          ),
        ),
        title: const Text(
          'Categories',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.85,
          children: [
            _CategoryCard(
              title: 'Tech',
              fontSize: 40,
              imagePath: 'assets/images/tech_category.jpg',
              gradientOverlay: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF00FFE1), // 100% opacity
                  Color(0x8000FFE1), // 50% opacity
                  Color(0x0000FFE1), // 0% opacity
                ],
                stops: [0.0, 0.2, 1.0],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesTechScreen())),
            ),
            _CategoryCard(
              title: 'Outfit',
              fontSize: 40,
              imagePath: 'assets/images/outfit_category.jpg',
              gradientOverlay: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFFE6D399), // 100% opacity
                  Color(0x80E6D399), // 50% opacity
                  Color(0x00E6D399), // 0% opacity
                ],
                stops: [0.0, 0.2, 1.0],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesOutfitScreen())),
            ),
            _CategoryCard(
              title: 'Power Tools',
              fontSize: 40,
              imagePath: 'assets/images/power_tools_category.jpg',
              gradientOverlay: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF8A38F5), // 100% opacity
                  Color(0x808A38F5), // 50% opacity
                  Color(0x008A38F5), // 0% opacity
                ],
                stops: [0.0, 0.2, 1.0],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesPowerToolsScreen())),
            ),
            _CategoryCard(
              title: 'Camp Tools',
              fontSize: 40,
              imagePath: 'assets/images/camp_tools_category.jpg',
              gradientOverlay: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFF22C23A), // 100% opacity
                  Color(0x8022C23A), // 50% opacity
                  Color(0x0022C23A), // 0% opacity
                ],
                stops: [0.0, 0.2, 1.0],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesCampToolsScreen())),
            ),
            _CategoryCard(
              title: 'Sports',
              fontSize: 40,
              imagePath: 'assets/images/sports_category.jpg',
              gradientOverlay: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFFF59D38), // 100% opacity
                  Color(0x80F59D38), // 50% opacity
                  Color(0x00F59D38), // 0% opacity
                ],
                stops: [0.0, 0.2, 1.0],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesSportsScreen())),
            ),
            _CategoryCard(
              title: 'Cook',
              fontSize: 40,
              imagePath: 'assets/images/cook_category.jpg',
              gradientOverlay: const LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Color(0xFFF53838), // 100% opacity
                  Color(0x80F53838), // 50% opacity
                  Color(0x00F53838), // 0% opacity
                ],
                stops: [0.0, 0.2, 1.0],
              ),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesCookScreen())),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final double fontSize;
  final String? imagePath;
  final Gradient? gradientOverlay;
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.fontSize,
    this.imagePath,
    this.gradientOverlay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFD9D9D9), // card_placeholder
          borderRadius: BorderRadius.circular(10),
          image: imagePath != null
              ? DecorationImage(
                  image: AssetImage(imagePath!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            // Linear Gradient Overlay (jika ada)
            if (gradientOverlay != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: gradientOverlay,
                  ),
                ),
              ),
            // Default dark overlay jika tidak ada gradient khusus
            if (gradientOverlay == null && imagePath != null)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: fontSize,
                    color: const Color(0xFFFFFFFF),
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
