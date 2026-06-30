import 'package:flutter/material.dart';

/// Kontainer dasar yang memiliki animasi pulsing shimmer secara sinkron.
class ShimmerContainer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            shape: widget.shape,
            borderRadius: widget.shape == BoxShape.rectangle
                ? (widget.borderRadius ?? BorderRadius.circular(12))
                : null,
            color: Color.lerp(
              const Color(0xFFEFEBE4), // Krem abu sangat terang
              const Color(0xFFE5DEC9), // Sedikit lebih gelap/hangat
              _animation.value,
            ),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder untuk kartu produk vertikal (ProductCard)
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF2F6743).withValues(alpha: 0.2), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Area Gambar
          const Expanded(
            child: ShimmerContainer(
              width: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          // Area Judul baris 1
          const ShimmerContainer(
            height: 12,
            width: double.infinity,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 6),
          // Area Judul baris 2 (lebih pendek)
          const ShimmerContainer(
            height: 12,
            width: 100,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
          const SizedBox(height: 12),
          // Area Harga
          const ShimmerContainer(
            height: 14,
            width: 80,
            borderRadius: BorderRadius.all(Radius.circular(4)),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder untuk kartu kategori (CategoriesScreen)
class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF012D1D).withValues(alpha: 0.1), width: 0.5),
      ),
      child: const ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: ShimmerContainer(
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
