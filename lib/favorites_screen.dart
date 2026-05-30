import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyFavorites = [
      {
        "name": "Sony Camera a6000",
        "owner": "Han so Hee",
        "date_range": "8 Apr - 10 Apr 2025",
        "image": "assets/images/Iklan.jpg",
      },
      {
        "name": "Sony Camera a6000",
        "owner": "Han so Hee",
        "date_range": "8 Mar - 10 Mar 2025",
        "image": "assets/images/Iklan.jpg",
      },
      {
        "name": "Sony Camera a6000",
        "owner": "Han so Hee",
        "date_range": "8 Jan - 10 Jan 2025",
        "image": "assets/images/Iklan.jpg",
      },
      {
        "name": "Sony Camera a6000",
        "owner": "Han so Hee",
        "date_range": "8 Jan - 10 Jan 2025",
        "image": "assets/images/Iklan.jpg",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Krem Terang
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDF9F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF012D1D)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "Favorite",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332), // Hijau Medium
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24.0),
        itemCount: dummyFavorites.length,
        itemBuilder: (context, index) {
          final item = dummyFavorites[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Image Thumbnail
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: AssetImage(item["image"]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["name"],
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600, // Semibold
                            color: Color(0xFF414844),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Pemilik: ${item['owner']}",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w400, // Regular
                            color: Color(0xFF414844),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              size: 14,
                              color: Color(0xFF414844),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item["date_range"],
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w400, // Regular
                                color: Color(0xFF414844),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Favorite Icon (Optional enhancement to indicate it's a favorite)
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFF2F6743), // Hijau SewaInAja
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
