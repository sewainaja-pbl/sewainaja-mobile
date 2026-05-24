import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'map_common_widgets.dart';
import 'widgets/success_rental_modal.dart';

class AjukanSewaScreen extends StatefulWidget {
  const AjukanSewaScreen({super.key});

  @override
  State<AjukanSewaScreen> createState() => _AjukanSewaScreenState();
}

class _AjukanSewaScreenState extends State<AjukanSewaScreen> {
  final LatLng _itemLocation = const LatLng(-6.9791, 110.4208);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFDF9F4,
      ), // Background Utama ID: '300:1159'
      // --- SECTION 1: APPBAR / HEADER ---
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
              // Back Button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF012D1D), // Circle Background: #012D1D
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFFFDF9F4),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Title: "Ajukan"
              const Text(
                "Ajukan",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Color(0xFF012D1D),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 42),
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

      // --- MAIN BODY (Section 2 - 6) ---
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ### [SECTION 2: ITEM SUMMARY CARD]
            _buildItemSummaryCard(),
            const SizedBox(height: 32),

            // ### [SECTION 3: TENTUKAN DURASI SEWA (FORM GRID)]
            _buildDurationFormGrid(),
            const SizedBox(height: 32),

            // ### [SECTION 4: TOTAL DURASI INDICATOR]
            _buildTotalDurationIndicator(),
            const SizedBox(height: 32),

            // ### [SECTION 5: PETA LOKASI BARANG]
            _buildLocationMap(),
            const SizedBox(height: 32),

            // ### [SECTION 6: RINCIAN HARGA (PRICE BREAKDOWN)]
            _buildPriceBreakdownCard(),
            const SizedBox(height: 32),

            // ### [SECTION 7: CATATAN TAMBAHAN (TEXTAREA)]
            _buildAdditionalNotesField(),

            // Padding bottom extra agar konten tidak tertutup bottom navigation bar
            const SizedBox(height: 40),
          ],
        ),
      ),

      // --- ### [SECTION 7: BOTTOM ACTION BAR (CHECKOUT)] ---
      bottomNavigationBar: _buildBottomCheckoutBar(),
    );
  }

  // --- SECTION 2: PETA LOKASI BARANG ---
  Widget _buildLocationMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(
              Icons
                  .location_on_rounded, // Alternative fallback for boxicons:location
              size: 20,
              color: Color(0xFF012D1D),
            ),
            SizedBox(width: 8),
            Text(
              "Lokasi Barang", // ID: '300:1161'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF012D1D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10), // Smooth padded map look
          decoration: BoxDecoration(
            color: Colors.white, // ID: '300:1163' Fills: #FFFFFF
            borderRadius: BorderRadius.circular(30), // BorderRadius: 30px
            border: Border.all(
              color: const Color(
                0xFF1B4332,
              ).withValues(alpha: 0.5), // Outline: #1B4332 0.5px
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              25,
            ), // ID: '300:1166' -> BorderRadius: 25px
            child: ReusableMapCard(
              center: _itemLocation,
              zoom: 14,
              interactive: false,
              showCenterPin: false,
              markers: [MapMarkerData(point: _itemLocation, highlighted: true)],
              overlayLabel: 'Lokasi pemilik barang',
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 3: ITEM SUMMARY CARD ---
  Widget _buildItemSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // Background: #FFFFFF
        borderRadius: BorderRadius.circular(
          30,
        ), // Specs recommended up to 40px, making it smooth
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Image
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: const DecorationImage(
                image: AssetImage('assets/images/Iklan.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                // Category
                Text(
                  "Camera",
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800, // ExtraBold/Bold
                    fontSize: 11,
                    color: Color(0xFF7B5804), // Gold/Brown
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 4),
                // Title
                Text(
                  "Sony a6000 Body Only",
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700, // Bold
                    fontSize: 18,
                    height: 1.2,
                    color: Color(0xFF012D1D),
                  ),
                ),
                SizedBox(height: 8),
                // Price
                Text(
                  "Rp. 15.000,00/jam",
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500, // Medium
                    fontSize: 14,
                    color: Color(0xFF7B5804),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SECTION 3: TENTUKAN DURASI SEWA (FORM GRID) ---
  Widget _buildDurationFormGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Title
        Row(
          children: const [
            FaIcon(
              FontAwesomeIcons.calendarDays,
              size: 18,
              color: Color(0xFF012D1D),
            ),
            SizedBox(width: 10),
            Text(
              "Tentukan Durasi Sewa",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600, // SemiBold
                fontSize: 18,
                color: Color(0xFF012D1D),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // GRID 2x2 for Duration Inputs using a simple Wrap/Row solution
        Row(
          children: [
            Expanded(
              child: _buildInputBox(label: "Mulai", value: "15 April 2026"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputBox(label: "Selesai", value: "17 April 2026"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInputBox(label: "Jam ambil", value: "19:00"),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputBox(label: "Jam kembali", value: "19:00"),
            ),
          ],
        ),
      ],
    );
  }

  // Helper Component for Duration Form Grid
  Widget _buildInputBox({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF585D59), // Color_Text_Muted
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF012D1D), // Value Color
                ),
              ),
            ],
          ),
          const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: Color(0xFF585D59),
          ),
        ],
      ),
    );
  }

  // --- SECTION 4: TOTAL DURASI INDICATOR ---
  Widget _buildTotalDurationIndicator() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFC1ECD4), // Pale Mint Background
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Number Circle Indicator
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF012D1D), // Deep Forest
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                "3",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Text Label and Value
          const Text(
            "Total Durasi Sewa:",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500, // Medium
              fontSize: 14,
              color: Color(0xFF012D1D),
            ),
          ),
          const Spacer(),
          const Text(
            "3 Hari",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700, // Bold
              fontSize: 15,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }

  // --- SECTION 5: RINCIAN HARGA (PRICE BREAKDOWN) ---
  Widget _buildPriceBreakdownCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white, // ID: '311:1686'
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            "Rincian Harga",
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700, // Bold
              fontSize: 18,
              color: Color(0xFF1C1C19),
            ),
          ),
          const SizedBox(height: 20),

          // Price Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Biaya Sewa (3 days)",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                  color: Color(0xFF414844),
                ),
              ),
              Text(
                "Rp. 1.080.000",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1C1C19),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Custom Dotted Divider style line
          const Divider(
            color: Color(0xFFF1EDE8), // Color_Divider
            thickness: 1.5,
          ),

          const SizedBox(height: 16),

          // Total Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Total Harga",
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800, // ExtraBold
                  fontSize: 18,
                  color: Color(0xFF012D1D),
                ),
              ),
              Text(
                "Rp. 1.080.000",
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w700, // SemiBold/Bold
                  fontSize: 18,
                  color: Color(0xFF012D1D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- SECTION 6: CATATAN TAMBAHAN (TEXTAREA) ---
  Widget _buildAdditionalNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Catatan Tambahan (Opsional)",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700, // Bold
            fontSize: 14,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 96, // Specified height 96px
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3EE), // Input variant background
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: const TextField(
            maxLines: null, // multi line
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: Color(0xFF012D1D),
            ),
            decoration: InputDecoration(
              hintText: "Contoh: 'Tolong tambahkan charger baterai'",
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF717973), // Color_Text_Subtle
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 7: BOTTOM ACTION BAR (CHECKOUT) ---
  Widget _buildBottomCheckoutBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDF9F4), // Background
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 16),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Left Price Display
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "TOTAL",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700, // Bold
                      fontSize: 10,
                      letterSpacing: 1,
                      color: Color(0xFF414844),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Rp. 1.080.000",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700, // Bold
                      fontSize: 18,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ],
              ),
            ),
            // Right Checkout Action Button
            GestureDetector(
              onTap: () => SuccessRentalModal.show(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D), // Background Deep Green
                  borderRadius: BorderRadius.circular(9999), // Full pill
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Kirim Request",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
      ),
    );
  }
}
