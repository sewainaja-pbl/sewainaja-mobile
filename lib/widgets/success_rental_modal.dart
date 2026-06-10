import 'dart:ui';
import 'package:flutter/material.dart';

class SuccessRentalModal extends StatelessWidget {
  final String itemName;
  final String itemImage;
  final DateTime? startDate;
  final DateTime? endDate;

  const SuccessRentalModal({
    super.key,
    required this.itemName,
    required this.itemImage,
    this.startDate,
    this.endDate,
  });

  static void show(
    BuildContext context, {
    required String itemName,
    required String itemImage,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => SuccessRentalModal(
        itemName: itemName,
        itemImage: itemImage,
        startDate: startDate,
        endDate: endDate,
      ),
    );
  }

  String _formatDateRange() {
    if (startDate == null || endDate == null) return "Tanggal sewa";
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${startDate!.day} ${months[startDate!.month - 1]} - ${endDate!.day} ${months[endDate!.month - 1]} ${endDate!.year}';
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: 358,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: const Color(0xFFC1C8C2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section: Close Button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xFF414844),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Success Badge
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFC1ECD4),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: Color(0xFF012D1D),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Text Content
              const Text(
                "Permintaan Terkirim!",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012D1D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Pemilik barang akan meninjau permintaanmu. Kamu bisa memantau statusnya di menu Requests.",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w400, // Regular
                  color: Color(0xFF414844),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Rental Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3EE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Product Image
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey.shade200,
                        image: itemImage.isNotEmpty && (itemImage.startsWith('http') || itemImage.startsWith('assets/'))
                            ? DecorationImage(
                                image: itemImage.startsWith('http')
                                    ? NetworkImage(itemImage)
                                    : AssetImage(itemImage) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (itemImage.isEmpty || (!itemImage.startsWith('http') && !itemImage.startsWith('assets/')))
                          ? const Center(
                              child: Icon(
                                Icons.image_outlined,
                                color: Color(0xFF828282),
                                size: 24,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Rincian Sewa",
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF7B5804),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            itemName,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF012D1D),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_month_outlined,
                                size: 14,
                                color: Color(0xFF414844),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _formatDateRange(),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF414844),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Primary Action Button
              GestureDetector(
                onTap: () {
                  // Navigate back to Home
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(9999),
                    border: Border.all(
                      color: const Color(0xFF717973),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      "Kembali ke Beranda",
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
