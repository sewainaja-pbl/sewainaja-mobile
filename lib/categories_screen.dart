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
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesTechScreen())),
            ),
            _CategoryCard(
              title: 'Power Tools',
              fontSize: 40,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesPowerToolsScreen())),
            ),
            _CategoryCard(
              title: 'Camp Tools',
              fontSize: 40,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesCampToolsScreen())),
            ),
            _CategoryCard(
              title: 'Sports',
              fontSize: 32,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesSportsScreen())),
            ),
            _CategoryCard(
              title: 'Cook',
              fontSize: 40,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesCookScreen())),
            ),
            _CategoryCard(
              title: 'Outfit',
              fontSize: 40,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesOutfitScreen())),
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
  final VoidCallback? onTap;

  const _CategoryCard({
    required this.title,
    required this.fontSize,
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
        ),
        child: Stack(
          children: [
            // If there were background images, they'd go here.
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
