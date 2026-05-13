import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const EditProfileScreen({super.key, this.onBack});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Color_Background
      
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
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
                child: const Icon(
                  Icons.arrow_back_rounded, // ID: '536:1764'
                  color: Color(0xFF012D1D),
                  size: 28,
                ),
              ),
              const Spacer(),
              // Title "Edit Profile"
              const Text(
                "Edit Profile", // ID: '536:1766'
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24, // Using 24 instead of 30 to prevent overflow and match modern app scales
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Color(0xFF1B4332), // Color_Primary
                ),
              ),
              const Spacer(),
              // Placeholder for balance
              const SizedBox(width: 28),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFF919191).withValues(alpha: 0.3), // Divider Stroke
            height: 1.0,
          ),
        ),
      ),

      // --- MAIN BODY ---
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40), // Spacing for scroll
        child: Column(
          children: [
            const SizedBox(height: 32),

            // ### [SECTION 2: AVATAR EDIT SECTION] ###
            _buildAvatarSection(),
            
            const SizedBox(height: 32),

            // ### [SECTION 3: PROFILE FORM CARD] ###
            _buildProfileFormCard(),
          ],
        ),
      ),

      // --- SECTION 4: BOTTOM ACTION BAR (FIXED) ---
      bottomNavigationBar: _buildBottomActionBar(),
    );
  }

  // Widget for Section 2: Avatar
  Widget _buildAvatarSection() {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Circular Avatar (ID: '536:1925')
          Container(
            width: 102,
            height: 102,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF1B4332).withValues(alpha: 0.2), // Subtle border
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(51),
              child: Image.asset(
                'assets/images/profile_user.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Edit Badge Overlay (ID: '536:1932')
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white, // ID: '536:1931' Background Kotak
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.edit_rounded, // ID: '536:1929' Edit Icon
                color: Color(0xFF012D1D),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Section 3: Form Card
  Widget _buildProfileFormCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // ID: '536:1933' Background
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // 3A. NAMA
          _buildFormRow(
            label: "Nama", // ID: '536:1945'
            value: "Han Soo Hee", // ID: '536:2158'
          ),
          const SizedBox(height: 16),
          
          // 3B. EMAIL
          _buildFormRow(
            label: "Email", // ID: '536:1946'
            value: "hansoohee@gmail.com", // ID: '536:2159'
          ),
          const SizedBox(height: 16),
          
          // 3C. NO TELPON
          _buildFormRow(
            label: "No. Telpon", // ID: '536:1948'
            value: "+62081234567890", // ID: '536:2161'
          ),
          const SizedBox(height: 16),
          
          // 3D. ALAMAT & MAP
          _buildAddressRow(),
        ],
      ),
    );
  }

  // Helper to build standard Row (Nama, Email, Telpon)
  Widget _buildFormRow({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE1), // Color_Row_Bg: Soft Beige
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans', // Fallback to Poppins if missing, but we assume it works
              fontSize: 14,
              fontWeight: FontWeight.w600, // SemiBold
              color: Color(0xFF1B4332), // Color_Primary
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                fontWeight: FontWeight.w400, // Regular
                color: Colors.black, // Color_Text_Main
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper to build Address Row (includes Map)
  Widget _buildAddressRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0ECE1), // Soft Beige
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Alamat", // ID: '536:1950'
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1B4332),
                ),
              ),
              Expanded(
                child: Text(
                  "Jl. Gondang Rayam...", // ID: '536:2186'
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Map Image Component (ID: '536:2196')
          Container(
            height: 120, // Specific height to show map clearly
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFF012D1D).withValues(alpha: 0.5), // Outline: #012D1D 0.5px equivalent
                width: 0.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.asset(
                'assets/images/map_preview.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Section 4: Bottom Action Bar
  Widget _buildBottomActionBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 20, top: 10),
        child: GestureDetector(
          onTap: () {
            // Confirm action
            if (widget.onBack != null) {
              widget.onBack!(); // Return home after confirm as simple prototype UX
            } else {
              Navigator.maybePop(context);
            }
          },
          child: Container(
            height: 54, // Modern standard button height
            decoration: BoxDecoration(
              color: const Color(0xFF1B4332), // Color_Primary
              borderRadius: BorderRadius.circular(25), // Pill Shape
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4332).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "Konfirmasi", // ID: '536:2156'
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
