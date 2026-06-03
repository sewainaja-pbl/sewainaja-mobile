import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'return_item_scan_screen.dart';

class RentalDeadlineScreen extends StatelessWidget {
  const RentalDeadlineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFFDF9F4),
        centerTitle: true,
        title: const Text(
          'Tenggat',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF012D1D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCountdownTimer(),
            const SizedBox(height: 16),
            _buildTimeDetails(),
            const SizedBox(height: 24),
            _buildTimelineStatus(),
            const SizedBox(height: 24),
            _buildItemCard(),
            const SizedBox(height: 24),
            _buildLocationMap(),
            const SizedBox(height: 32),
            _buildBottomActions(context),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownTimer() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2F6743),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Sisa Waktu',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFFFFF),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimerBlock('01', 'Hari'),
              _buildSeparator(),
              _buildTimerBlock('12', 'Jam'),
              _buildSeparator(),
              _buildTimerBlock('30', 'Menit'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimerBlock(String value, String label) {
    return Column(
      children: [
        Container(
          width: 70,
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF012D1D),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFF8EF),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Text(
        ':',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Color(0xFF012D1D),
        ),
      ),
    );
  }

  Widget _buildTimeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '8 Jan(Mulai)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF414844),
              ),
            ),
            Text(
              '10 Jan 2025(Selesai)',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Color(0xFF414844),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFBDBDBD), // Empty grey
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2F6743), Color(0xFFA2D7B4)],
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Expanded(
                flex: 2,
                child: SizedBox(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineStatus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Status',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF414844),
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineItem('H-24: Sewa berakhir besok pukul 10:00', const Color(0xFFF8BD00)),
        const SizedBox(height: 12),
        _buildTimelineItem('Serah Terima Berhasil Konfirmasi', const Color(0xFF2F6743)),
        const SizedBox(height: 12),
        _buildTimelineItem('Request sewa disetujui pemilik', const Color(0xFF2F6743)),
      ],
    );
  }

  Widget _buildTimelineItem(String text, Color dotColor) {
    return Row(
      children: [
        const SizedBox(width: 4), // Small indent for the dot
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Color(0xFF414844),
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/camera_sony.jpg',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sony Camera a6000',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF414844),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Pemilik: Han so Hee',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF414844),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  '8 Jan - 10 Jan 2025',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Color(0xFF414844),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationMap() {
    const itemLocation = LatLng(-6.966667, 110.416664);
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            height: 150,
            width: double.infinity,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: itemLocation,
                initialZoom: 14,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.sewainaja.app',
                ),
                const MarkerLayer(
                  markers: [
                    Marker(
                      point: itemLocation,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF012D1D),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Text(
              'Lokasi Barang',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Column(
      children: [
        _buildActionButton(
          'Kembalikan',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReturnItemScanScreen()),
            );
          },
        ),
        const SizedBox(height: 12),
        _buildActionButton('Request Perpanjangan'),
      ],
    );
  }

  Widget _buildActionButton(String text, {VoidCallback? onPressed}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed ?? () {},
        style: OutlinedButton.styleFrom(
          backgroundColor: const Color(0xFFFFFFFF),
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Color(0xFF012D1D), width: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332),
          ),
        ),
      ),
    );
  }
}
