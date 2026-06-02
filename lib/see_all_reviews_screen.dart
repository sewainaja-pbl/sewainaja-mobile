import 'package:flutter/material.dart';

class SeeAllReviewsScreen extends StatelessWidget {
  final String ownerName;

  const SeeAllReviewsScreen({
    super.key,
    this.ownerName = "Mas Tahes",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      body: CustomScrollView(
        slivers: [
          // --- 1A. TOP APP BAR ---
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: const Color(0xFFFFF8EF),
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Reviews for $ownerName",
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFF012D1D),
              ),
            ),
          ),

          // --- 1B. OVERALL RATING SECTION ---
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF9F4),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "4.3",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          fontSize: 48,
                          color: Color(0xFF012D1D),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          for (int i = 0; i < 4; i++)
                            const Icon(Icons.star, color: Color(0xFFF8BD00), size: 18),
                          const Icon(Icons.star_half, color: Color(0xFFF8BD00), size: 18),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "10 reviews",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Color(0xFF414844),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 24),
                  // Right Column (Distribution Bars)
                  Expanded(
                    child: Column(
                      children: [
                        _buildRatingBar("5", 0.7),
                        const SizedBox(height: 8),
                        _buildRatingBar("4", 0.2),
                        const SizedBox(height: 8),
                        _buildRatingBar("3", 0.1),
                        const SizedBox(height: 8),
                        _buildRatingBar("2", 0.0),
                        const SizedBox(height: 8),
                        _buildRatingBar("1", 0.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- 1C. REVIEWS LIST ---
          SliverPadding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildReviewCard(
                  name: "Sarah Jenkins",
                  date: "Dec 30, 2025",
                  rating: 5,
                  text: "Julian was incredibly helpful and the equipment was in perfect condition. Highly recommend renting from him!",
                  helpfulCount: 2,
                  itemImage: "assets/images/sony_camera.png",
                ),
                _buildReviewCard(
                  name: "Ceazar",
                  date: "Nov 15, 2025",
                  rating: 4,
                  text: "Barang ori, kondisinya mulus banget pas disewa. Orangnya juga ramah dan responnya cepat.",
                  helpfulCount: 1,
                  itemImage: "assets/images/ps5_controller.png",
                ),
                _buildReviewCard(
                  name: "Budi Santoso",
                  date: "Oct 02, 2025",
                  rating: 5,
                  text: "Sangat recommended! Alat yang disewakan sangat lengkap dan bersih. Proses serah terima juga mudah.",
                  helpfulCount: 0,
                  itemImage: null,
                ),
                _buildReviewCard(
                  name: "Ayu Kirana",
                  date: "Sep 28, 2025",
                  rating: 4,
                  text: "Kameranya berfungsi dengan baik. Hanya saja ada sedikit lecet di bagian bawah, tapi tidak memengaruhi performa.",
                  helpfulCount: 5,
                  itemImage: "assets/images/airpods_max.png",
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingBar(String star, double value) {
    return Row(
      children: [
        Text(
          star,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: Color(0xFF414844),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E2DD),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String name,
    required String date,
    required int rating,
    required String text,
    required int helpfulCount,
    String? itemImage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF9F4),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFE6E2DD)),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : 'U',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF012D1D),
                            ),
                          ),
                          Text(
                            date,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.normal,
                              fontSize: 12,
                              color: Color(0xFF414844),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    Icons.star,
                    size: 14,
                    color: index < rating ? const Color(0xFFF8BD00) : const Color(0xFFE6E2DD),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Review Text
          Text(
            text,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.normal,
              fontSize: 14,
              color: Color(0xFF1C1C19),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Footer Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Helpful Button
              () {
                bool isHelpful = false;
                return StatefulBuilder(
                  builder: (context, setState) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          isHelpful = !isHelpful;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isHelpful ? const Color(0xFFC1ECD4).withValues(alpha: 0.5) : const Color(0xFFFDF9F4),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isHelpful ? const Color(0xFF012D1D).withValues(alpha: 0.2) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isHelpful ? Icons.thumb_up_alt : Icons.thumb_up_off_alt,
                              size: 14,
                              color: const Color(0xFF012D1D),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Helpful (${isHelpful ? helpfulCount + 1 : helpfulCount})",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                color: Color(0xFF012D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }(),
              
              // Thumbnail
              if (itemImage != null)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFF5F5F5),
                    image: DecorationImage(
                      image: AssetImage(itemImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
