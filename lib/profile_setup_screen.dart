import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatelessWidget {
  const ProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF), // Warna bg_surface
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),

              // ==========================================
              // HEADER
              // ==========================================
              const Text(
                'Set photo profile',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(
                    0xFF012D1D,
                  ), // Menggunakan primary_green untuk konsistensi heading
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),

              // ==========================================
              // AVATAR DISPLAY & EDIT CONTROL
              // ==========================================
              Center(
                child: Stack(
                  children: [
                    // Placeholder Avatar
                    Container(
                      width: 160,
                      height: 160,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD9D9D9), // avatar_placeholder
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.camera_alt, // camera-solid
                          size: 60,
                          color: Color(0xFF000000), // icon_color
                        ),
                      ),
                    ),

                    // Edit Control (Icon Edit)
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFFFF), // background putih
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(
                              0xFF7B5804,
                            ), // border_color primary_action
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.edit_rounded, // edit-rounded
                          size: 24,
                          color: Color(0xFF7B5804), // icon_color primary_action
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // ==========================================
              // ACTIONS (CONFIRM ONLY)
              // ==========================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Aksi Confirm
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5804), // primary_action
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999), // pill_shape
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Confirm',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF), // white text
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
