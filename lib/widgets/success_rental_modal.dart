import 'dart:ui';
import 'package:flutter/material.dart';

class SuccessRentalModal extends StatelessWidget {
  const SuccessRentalModal({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => const SuccessRentalModal(),
    );
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
                borderRadius: BorderRadius.circular(24), // Adjusted from 40 for inner fit
              ),
              child: Row(
                children: [
                  // Product Image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/Iklan.jpg'),
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
                        const Text(
                          "Sony ɑ6000 Body Only",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 18, // Scaled down from 24 for inner fit
                            fontWeight: FontWeight.w600, // Semibold
                            color: Color(0xFF012D1D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(
                              Icons.calendar_month_outlined,
                              size: 14,
                              color: Color(0xFF414844),
                            ),
                            SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "12 Oct - 15 Oct",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans', // Fallback to Poppins or default if not registered
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400, // Regular
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
                      fontFamily: 'Plus Jakarta Sans', // Fallback to Poppins or default if not registered
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
