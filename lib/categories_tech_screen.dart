import 'package:flutter/material.dart';

class CategoriesTechScreen extends StatelessWidget {
  const CategoriesTechScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDF9F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Tech',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF7B5804),
            height: 1.0,
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
        border: Border.all(
          color: const Color(0xFF2F6743),
          width: 0.5,
        ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
