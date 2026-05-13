import 'package:flutter/material.dart';

class AddProductScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const AddProductScreen({super.key, this.onBack});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  String selectedKategori = "Elektronik";
  String selectedKondisi = "Sangat Baik";
  String selectedDurasi = "Hari";

  final List<String> kategoriList = ["Elektronik", "Peralatan", "Pakaian", "Olahraga", "Lainnya"];
  final List<String> kondisiList = ["Baru", "Sangat Baik", "Baik", "Cukup"];
  final List<String> durasiList = ["Jam", "Hari", "Minggu"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Background Utama ID: '256:3153'
      
      // --- SECTION 1: APPBAR / HEADER ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
        titleSpacing: 24,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
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
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFF012D1D), // Circle Background: #012D1D
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 22,
                      color: Color(0xFFFDF9F4),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Title: "Add Product"
              const Text(
                "Add Product",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w700, // SemiBold / Bold in screen spec
                  color: Color(0xFF012D1D),
                ),
              ),
              const Spacer(),
              // Hidden dummy to keep title perfectly centered
              const SizedBox(width: 42),
            ],
          ),
        ),
      ),

      // --- MAIN SCROLLABLE CONTENT (Section 2 - 4) ---
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ### [SECTION 2: FOTO BARANG (IMAGE UPLOAD GRID)]
            _buildPhotoUploadSection(),
            const SizedBox(height: 28),

            // ### [SECTION 3: FORM INFORMASI BARANG]
            _buildProductFormCard(),
            const SizedBox(height: 32),

            // ### [SECTION 4: LOKASI BARANG (MAP PREVIEW)]
            _buildLocationMap(),
            const SizedBox(height: 32),

            // ### [SECTION 5: TAMBAH KE MARKETPLACE BUTTON]
            _buildBottomActionButton(),
            
            // Padding bottom extra agar seimbang di bawah layar
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- SECTION 2: FOTO BARANG UI ---
  Widget _buildPhotoUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Row Header: Title & Limit
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: const [
            Text(
              "Foto Barang", // ID: '268:3247'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF012D1D),
              ),
            ),
            Text(
              "Maks 5 Foto", // ID: '268:3465'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF7B5804), // Gold / Accent Color
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Baris 1: 2 Slot Besar
        Row(
          children: [
            Expanded(child: _buildBigUploadSlot()),
            const SizedBox(width: 16),
            Expanded(child: _buildBigUploadSlot()),
          ],
        ),
        const SizedBox(height: 16),

        // Baris 2: 3 Slot Kecil
        Row(
          children: [
            Expanded(child: _buildSmallUploadSlot()),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallUploadSlot()),
            const SizedBox(width: 16),
            Expanded(child: _buildSmallUploadSlot()),
          ],
        ),
      ],
    );
  }

  // Helper widget for Big Photo Slot
  Widget _buildBigUploadSlot() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Radius 40px
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circle Background for Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFF7F3EE), // Soft Grey/Cream Variant
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE2DCD3),
                width: 0.5,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.camera_enhance_outlined,
                color: Color(0xFF1B4332), // Camera Icon Color
                size: 24,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Texts
          const Text(
            "Unggah Foto",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "JPG, PNG (Max 5MB)",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Color(0xFF5C635E), // Subtitle color
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget for Small Photo Slot
  Widget _buildSmallUploadSlot() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Radius 40px (Pill)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.add,
          color: Color(0xFF1B4332),
          size: 20,
        ),
      ),
    );
  }

  // --- SECTION 3: PRODUCT FORM CARD ---
  Widget _buildProductFormCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40), // Large outer card radius
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nama Barang
          _buildLabel("Nama Barang"),
          const SizedBox(height: 8),
          _buildTextInput(hint: "Contoh: Kamera Canon Eos M100"),
          const SizedBox(height: 20),

          // Deskripsi Barang
          _buildLabel("Deskripsi Barang"),
          const SizedBox(height: 8),
          _buildTextInput(
            hint: "Contoh: Kamera Profesional dengan",
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Row: Kategori & Kondisi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Kategori"),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedKategori,
                      items: kategoriList,
                      onChanged: (val) => setState(() => selectedKategori = val!),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Kondisi"),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedKondisi,
                      items: kondisiList,
                      onChanged: (val) => setState(() => selectedKondisi = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row: Harga Sewa & Durasi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Harga Sewa"),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      hint: "0",
                      prefix: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Text(
                          "Rp. ",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF012D1D),
                          ),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel("Jam/Hari"),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: selectedDurasi,
                      items: durasiList,
                      onChanged: (val) => setState(() => selectedDurasi = val!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper for Labels
  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600, // SemiBold
        color: Color(0xFF012D1D),
      ),
    );
  }

  // Helper for Standard Text Inputs
  Widget _buildTextInput({
    required String hint,
    int maxLines = 1,
    Widget? prefix,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9), // Updated to #D9D9D9
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF012D1D), // High contrast deep green
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: Color(0xFF717973), // Standard muted gray hint
          ),
          prefixIcon: prefix,
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // Helper for Dropdowns
  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9), // Updated to #D9D9D9
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFFD9D9D9), // Matches dropdown bg
          icon: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0xFF012D1D), // Standard icon color
            size: 24,
          ),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF012D1D), // Standard text color
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String val) {
            return DropdownMenuItem<String>(
              value: val,
              child: Text(val),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- SECTION 4: LOKASI BARANG ---
  Widget _buildLocationMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Lokasi Barang", // ID: '268:3642'
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(10), // Inner map container
          decoration: BoxDecoration(
            color: Colors.white, // ID: '268:3645'
            borderRadius: BorderRadius.circular(30), // Outer radius
            border: Border.all(
              color: const Color(0xFF1B4332).withValues(alpha: 0.5), // Outline 0.5px
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
            borderRadius: BorderRadius.circular(25), // ID: '268:3648' -> BorderRadius: 25px
            child: Image.asset(
              'assets/images/map_preview.png',
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
    );
  }

  // --- SECTION 5: BOTTOM ACTION BUTTON ---
  Widget _buildBottomActionButton() {
    return GestureDetector(
      onTap: () {
        // Add action logic here (e.g., validating form, submitting to backend)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Barang ditambahkan ke Marketplace")),
        );
      },
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF012D1D), // ID: '268:3651'
          borderRadius: BorderRadius.circular(180), // Pill shape
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF012D1D).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "Tambah ke Marketplace", // ID: '268:3652'
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700, // Bold
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
