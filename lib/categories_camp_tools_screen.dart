import 'dart:ui';
import 'package:flutter/material.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';

class CategoriesCampToolsScreen extends StatelessWidget {
  const CategoriesCampToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "name": "Tenda Camping Dome 4 Orang",
        "price": "Rp.80,000/Day",
        "rating": "4.8(192)",
        "image": "assets/images/tenda_camping.png",
      },
      {
        "name": "Tas Carrier Outdoor 60L",
        "price": "Rp.45,000/Day",
        "rating": "4.7(120)",
        "image": "assets/images/tas_carrier.png",
      },
      {
        "name": "Sleeping Bag Mummy Premium",
        "price": "Rp.25,000/Day",
        "rating": "4.9(78)",
        "image": "assets/images/sleeping_bag.png",
      },
      {
        "name": "Kompor Camping Portable Gas",
        "price": "Rp.20,000/Day",
        "rating": "4.8(115)",
        "image": "assets/images/kompor_camping.png",
      },
      {
        "name": "Lentera LED Camping Rechargeable",
        "price": "Rp.15,000/Day",
        "rating": "4.6(43)",
        "image": "assets/images/lentera_camping.png",
      },
      {
        "name": "Matras Angin Camping Double",
        "price": "Rp.35,000/Day",
        "rating": "4.8(62)",
        "image": "assets/images/matras_camping.png",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4).withValues(alpha: 0.6),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 24,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
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
                'Camp Tools',
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
      body: GridView.builder(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 80 + 16,
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
        itemCount: items.length,
        itemBuilder: (context, index) {
          final product = ProductData(
            name: items[index]["name"]!,
            price: items[index]["price"]!,
            rating: items[index]["rating"]!,
            image: items[index]["image"]!,
          );
          return ProductCard(product: product);
        },
      ),
    );
  }
}
