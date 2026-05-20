import 'package:flutter/material.dart';

class CategoriesPowerToolsScreen extends StatelessWidget {
  const CategoriesPowerToolsScreen({super.key});

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
                'Power Tools',
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
                "name": "Bor Listrik Cordless 12V",
                "price": "Rp.50,000/Day",
                "rating": "4.8(124)",
                "image": "assets/images/bor_listrik.png",
              },
              {
                "name": "Mesin Gerinda Tangan 4-Inch",
                "price": "Rp.45,000/Day",
                "rating": "4.7(88)",
                "image": "assets/images/mesin_gerinda.png",
              },
              {
                "name": "Gergaji Circular Listrik 7-Inch",
                "price": "Rp.75,000/Day",
                "rating": "4.9(42)",
                "image": "assets/images/gergaji_circular.png",
              },
              {
                "name": "Obeng Listrik Cordless Mini",
                "price": "Rp.30,000/Day",
                "rating": "4.6(15)",
                "image": "assets/images/obeng_listrik.png",
              },
              {
                "name": "Mesin Serut Kayu Listrik",
                "price": "Rp.60,000/Day",
                "rating": "4.8(54)",
                "image": "assets/images/mesin_serut.png",
              },
              {
                "name": "Mesin Amplas Listrik",
                "price": "Rp.35,000/Day",
                "rating": "4.7(29)",
                "image": "assets/images/mesin_amplas.png",
              },
            ];

            return _ProductCard(
              name: items[index]["name"]!,
              price: items[index]["price"]!,
              rating: items[index]["rating"]!,
              imagePath: items[index]["image"]!,
            );
          },
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final String rating;
  final String imagePath;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.rating,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF2F6743), width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Placeholder with Rating Badge
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9D9D9), // Placeholder color
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: AssetImage(imagePath),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFF8BD00),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              color: Color(0xFFFFF8EF),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Product Name and Action Icon
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF414844),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: Color(0xFF414844),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Price Tag
            Text(
              price,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF414844),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
