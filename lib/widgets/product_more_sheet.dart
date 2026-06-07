import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../image_upload_service.dart';
import '../add_product_screen.dart';
import 'package:http/http.dart' as http;
import '../api_config.dart';
import '../auth_session_service.dart';
import '../app_feedback.dart';

/// Membuka Bottom Sheet gaya Tokopedia/Shopee untuk aksi tambahan pada kartu produk.
void showProductMoreSheet({
  required BuildContext context,
  required ProductData product,
  bool isFavorite = false,
  required VoidCallback onFavoritePressed,
  required VoidCallback onSimilarPressed,
  required VoidCallback onNotInterestedPressed,
  required VoidCallback onReportPressed,
  VoidCallback? onEditPressed,
  VoidCallback? onDeletePressed,
}) {
  ImageProvider buildImageProvider(String imagePath) {
    if (product.isLocalAsset) {
      return FileImage(File(imagePath));
    }
    final safeUrl = getSafeImageUrl(imagePath);
    if (safeUrl.startsWith('http://') || safeUrl.startsWith('https://')) {
      return ResizeImage(CachedNetworkImageProvider(safeUrl), width: 120);
    }
    return AssetImage(safeUrl);
  }

  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final String? ownerId = product.originalItem?.ownerId;
  final bool isOwnItem = currentUserId != null && ownerId == currentUserId;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Product Detail Info Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0),
                        width: 0.5,
                      ),
                      image: product.image.isNotEmpty
                          ? DecorationImage(
                              image: buildImageProvider(product.image),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: product.image.isEmpty
                        ? const Icon(
                            Icons.image_not_supported_outlined,
                            color: Color(0xFFB0B0B0),
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                        Text(
                          product.price.contains('/')
                              ? product.price
                              : "${product.price}/Day",
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 8),

            // Options List
            _buildOptionItem(
              context: context,
              icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              iconColor: isFavorite ? const Color(0xFFE33629) : const Color(0xFF012D1D),
              title: isFavorite ? 'Hapus dari Favorit' : 'Simpan ke Favorit',
              onTap: () {
                Navigator.pop(context);
                onFavoritePressed();
              },
            ),
            _buildOptionItem(
              context: context,
              icon: Icons.search_rounded,
              iconColor: const Color(0xFF012D1D),
              title: 'Cari Produk Serupa',
              onTap: () {
                Navigator.pop(context);
                onSimilarPressed();
              },
            ),
            if (isOwnItem || onEditPressed != null)
              _buildOptionItem(
                context: context,
                icon: Icons.edit_rounded,
                iconColor: const Color(0xFF012D1D),
                title: 'Edit Barang',
                onTap: () {
                  Navigator.pop(context);
                  if (onEditPressed != null) {
                    onEditPressed();
                  } else if (product.originalItem != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddProductScreen(editItem: product.originalItem!),
                      ),
                    );
                  }
                },
              ),
            _buildOptionItem(
              context: context,
              icon: Icons.sentiment_dissatisfied_rounded,
              iconColor: const Color(0xFF012D1D),
              title: 'Produk Tidak Menarik',
              onTap: () {
                Navigator.pop(context);
                onNotInterestedPressed();
              },
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: 0.5, color: Color(0xFFE0E0E0)),
            const SizedBox(height: 8),
            if (isOwnItem || onDeletePressed != null)
              _buildOptionItem(
                context: context,
                icon: Icons.delete_outline_rounded,
                iconColor: const Color(0xFFE33629),
                title: 'Hapus Barang',
                isDanger: true,
                onTap: () async {
                  Navigator.pop(context);
                  if (onDeletePressed != null) {
                    onDeletePressed();
                  } else if (product.originalItem != null) {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFFFFF8EF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text('Hapus Barang?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                        content: const Text('Apakah Anda yakin ingin menghapus barang ini? Status barang akan diarsipkan.', style: TextStyle(fontFamily: 'Poppins')),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Batal', style: TextStyle(color: Color(0xFF585D59))),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE33629),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        final token = await const AuthSessionService().getValidIdToken();
                        final response = await http.delete(
                          Uri.parse('${ApiConfig.baseUrl}/items/${product.id}'),
                          headers: {'Authorization': 'Bearer $token'},
                        );
                        if (response.statusCode == 200) {
                          if (!context.mounted) return;
                          showAppSuccessSnack(context, 'Barang berhasil dihapus!');
                        }
                      } catch (_) {
                      }
                    }
                  }
                },
              )
            else
              _buildOptionItem(
                context: context,
                icon: Icons.report_problem_rounded,
                iconColor: const Color(0xFFE33629),
                title: 'Laporkan Barang',
                isDanger: true,
                onTap: () {
                  Navigator.pop(context);
                  onReportPressed();
                },
              ),
          ],
        ),
      );
    },
  );
}

Widget _buildOptionItem({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  required VoidCallback onTap,
  bool isDanger = false,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: iconColor,
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              fontWeight: isDanger ? FontWeight.w600 : FontWeight.w500,
              color: isDanger ? const Color(0xFFE33629) : const Color(0xFF414844),
            ),
          ),
        ],
      ),
    ),
  );
}
