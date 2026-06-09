import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../image_upload_service.dart';

/// Widget kartu produk yang support baik asset image maupun network image.
/// Gunakan [ProductCard] dengan [ProductData] untuk data legacy/static,
/// atau gunakan [ProductCard.fromNetwork] untuk data dari Firestore.
class ProductCard extends StatelessWidget {
  final ProductData product;
  final bool isHorizontal;
  final VoidCallback? onMorePressed;

  const ProductCard({
    super.key,
    required this.product,
    this.isHorizontal = false,
    this.onMorePressed,
  });

  /// Membangun ImageProvider yang tepat:
  /// - Jika image adalah path lokal -> FileImage
  /// - Jika image dimulai dengan "http" → NetworkImage
  /// - Selain itu → AssetImage
  ImageProvider _buildImageProvider(String imagePath) {
    if (product.isLocalAsset) {
      return FileImage(File(imagePath));
    }
    final safeUrl = getSafeImageUrl(imagePath);
    if (safeUrl.startsWith('http://') || safeUrl.startsWith('https://')) {
      return ResizeImage(
        CachedNetworkImageProvider(safeUrl),
        width: 200, // Optimize memory for horizontal card preview
      );
    }
    return AssetImage(safeUrl);
  }

  @override
  Widget build(BuildContext context) {
    if (isHorizontal) {
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF2F6743),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Hero(
              tag: 'product-image-${product.id ?? product.name}',
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(15),
                  ),
                  image: product.image.isNotEmpty
                      ? DecorationImage(
                          image: _buildImageProvider(product.image),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: product.image.isEmpty
                    ? const Icon(Icons.image_not_supported_outlined,
                        color: Color(0xFFB0B0B0))
                    : null,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF414844),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFF8BD00),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          product.rating.toString(),
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF414844),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      product.price.contains('/')
                          ? product.price
                          : "${product.price}/Day",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF012D1D),
              ),
            ),
          ],
        ),
      );
    }

    // Vertical card for grid/slider
    final safeImage = getSafeImageUrl(product.image);
    final bool isNetworkImage =
        safeImage.startsWith('http://') ||
        safeImage.startsWith('https://');

    return Container(
      width: 160,
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
            // Image with Rating Badge
            Expanded(
              child: Stack(
                children: [
                  Hero(
                    tag: 'product-image-${product.id ?? product.name}',
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D9D9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: product.image.isEmpty
                            ? const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Color(0xFFB0B0B0),
                                  size: 32,
                                ),
                              )
                            : isNetworkImage
                            ? CachedNetworkImage(
                                imageUrl: safeImage,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                memCacheWidth: 300,
                                placeholder: (context, url) => const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation(
                                        Color(0xFF012D1D),
                                      ),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Color(0xFFB0B0B0),
                                    size: 32,
                                  ),
                                ),
                              )
                            : Image.asset(
                                product.image,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                cacheWidth: 350,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Color(0xFFB0B0B0),
                                    size: 32,
                                  ),
                                ),
                              ),
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
                            product.rating.toString(),
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
                    product.name,
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
                GestureDetector(
                  onTap: onMorePressed,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.more_horiz,
                      size: 18,
                      color: Color(0xFF414844),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Price Tag
            Text(
              product.price.contains('/')
                  ? product.price
                  : "${product.price}/Day",
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
