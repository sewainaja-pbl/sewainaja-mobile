import 'package:flutter/material.dart';
import 'models/product.dart';
import 'widgets/product_card.dart';
import 'item_detail_screen.dart';

class NewArrivalsScreen extends StatelessWidget {
  const NewArrivalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Generate a rich set of 10 mock products for New Arrivals
    final baseProducts = [
      ProductData(
        name: "Sony W830 Camera",
        price: "Rp.120,000",
        rating: "4.8(292)",
        image: 'assets/images/sony_camera.png',
      ),
      ProductData(
        name: "Sony Dual-Sense PS5",
        price: "Rp.45,000",
        rating: "4.8(180)",
        image: 'assets/images/ps5_controller.png',
      ),
      ProductData(
        name: "Apple Airpods Max 2",
        price: "Rp.45,000",
        rating: "4.9(340)",
        image: 'assets/images/airpods_max.png',
      ),
    ];

    final List<ProductData> products = List.generate(12, (index) {
      final base = baseProducts[index % baseProducts.length];
      return ProductData(
        name: index >= baseProducts.length 
            ? "${base.name} Pro #${index - 1}"
            : base.name,
        price: base.price,
        rating: base.rating,
        image: base.image,
      );
    });

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
                'New Arrivals',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
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
            childAspectRatio: 0.65,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ItemDetailScreen(),
                ),
              ),
              child: ProductCard(product: product),
            );
          },
        ),
      ),
    );
  }
}
