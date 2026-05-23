import 'package:flutter/material.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';

class CategoriesTechScreen extends StatelessWidget {
  const CategoriesTechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 24,
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
                'Tech',
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.65, // Adjusted to fit image, title, and price
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            final items = [
              {
                "name": "Vivo Y15s 8/128GB",
                "price": "Rp.120,000/Day",
                "rating": "4.8(292)",
                "image": "assets/images/handphone.jpg",
              },
              {
                "name": "Realme C55 12/512GB",
                "price": "Rp.45,000/Day",
                "rating": "4.8(292)",
                "image": "assets/images/hp_realme.jpg",
              },
              {
                "name": "EOS 5D Mark IV",
                "price": "Rp.120,000/Day",
                "rating": "4.8(292)",
                "image": "assets/images/camera_canon.jpg",
              },
              {
                "name": "Sony FX30",
                "price": "Rp.45,000/Day",
                "rating": "4.8(292)",
                "image": "assets/images/camera_sony.jpg",
              },
              {
                "name": "Asus Zenfone 12 Ultra 16/512GB",
                "price": "Rp.120,000/Day",
                "rating": "4.8(292)",
                "image": "assets/images/hp_asus.jpg",
              },
              {
                "name": "Nikon Coolpix B500",
                "price": "Rp.45,000/Day",
                "rating": "4.8(292)",
                "image": "assets/images/camera_nikon.jpg",
              },
            ];

            final product = ProductData(
              name: items[index]["name"]!,
              price: items[index]["price"]!,
              rating: items[index]["rating"]!,
              image: items[index]["image"]!,
            );
            return ProductCard(product: product);
          },
        ),
      ),
    );
  }
}


