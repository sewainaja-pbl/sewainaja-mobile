import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({super.key});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  // State untuk 6 slot input OTP
  final List<TextEditingController> _otpControllers =
      List.generate(6, (index) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(6, (index) => FocusNode());

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF), // Warna bg_surface
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 24),

              // ==========================================
              // ILLUSTRATION PLACEHOLDER
              // ==========================================
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFFC1ECD4).withOpacity(0.3), // nature_accent opsional bg
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 80,
                    color: Color(0xFF7B5804), // primary_brown
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ==========================================
              // HEADER & INSTRUCTION
              // ==========================================
              const Text(
                'Verifikasi OTP',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 40,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Color(0xFF012D1D), // dark_green
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Masukan 6 digit kode dari aplikasi authenticator...',
                style: TextStyle(
                  fontFamily: 'Inter', // Fallback ke default sistem jika Inter tidak diregistrasi
                  fontSize: 15,
                  color: Color(0xFF414844), // text_muted
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // ==========================================
              // OTP INPUT GROUP (6 SLOTS)
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _otpControllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1, // Batasi 1 karakter per kotak
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF012D1D),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        counterText: "", // Sembunyikan counter karakter
                        filled: true,
                        fillColor: const Color(0xFFFFFFFF), // soft_white
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF7B5804),
                            width: 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF7B5804),
                            width: 2.0,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        // Pindah fokus ke kotak berikutnya jika diisi
                        if (value.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        }
                        // Mundur fokus jika dihapus
                        else if (value.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                      },
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // ==========================================
              // TIMER & RESEND ACTION
              // ==========================================
              const Text(
                '2:53',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF414844),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // TODO: Aksi kirim ulang OTP
                },
                child: const Text(
                  'Kirim ulang OTP? RESEND',
                  style: TextStyle(
                    fontFamily: 'Poppins', // Menggunakan Poppins karena PingFang SC tidak ada di config
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF7B5804), // primary_brown
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // ==========================================
              // SUBMIT BUTTON
              // ==========================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Aksi konfirmasi OTP
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5804), // primary_brown
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999), // pill shape
                    ),
                  ),
                  child: const Text(
                    'Konfirmasi OTP',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF), // text_color
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