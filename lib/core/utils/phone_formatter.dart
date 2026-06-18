import 'package:flutter/services.dart';

/// Utility untuk format & masking nomor telepon Indonesia ke format E.164.
class PhoneFormatter {
  /// Konversi berbagai format nomor HP Indonesia ke format E.164 (+62xxx).
  ///
  /// Contoh:
  ///   "081234567890"   → "+6281234567890"
  ///   "6281234567890"  → "+6281234567890"
  ///   "+6281234567890" → "+6281234567890" (no-op)
  ///   "81234567890"    → "+6281234567890"
  static String toE164Format(String phone) {
    // Bersihkan spasi dan tanda hubung
    String cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '').trim();

    if (cleaned.startsWith('+62')) {
      return cleaned;
    } else if (cleaned.startsWith('62')) {
      return '+$cleaned';
    } else if (cleaned.startsWith('0')) {
      return '+62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('8')) {
      return '+62$cleaned';
    } else {
      // Asumsikan sudah tanpa kode negara, tambahkan +62
      return '+62$cleaned';
    }
  }

  /// Masking nomor HP untuk tampil ke user.
  /// Sembunyikan 4 digit di tengah.
  ///
  /// Contoh: "+6281234567890" → "+62812****7890"
  static String maskPhone(String phone) {
    if (phone.length < 8) return phone;

    // Ambil prefix (misal: +62812) dan suffix (4 digit terakhir)
    final prefix = phone.substring(0, phone.length - 8);
    final suffix = phone.substring(phone.length - 4);
    return '$prefix****$suffix';
  }

  /// Validasi apakah nomor HP Indonesia valid (8–13 digit setelah kode negara).
  static bool isValidIndonesianPhone(String phone) {
    final e164 = toE164Format(phone);
    // Format valid: +62 diikuti 7–12 digit
    return RegExp(r'^\+62\d{7,12}$').hasMatch(e164);
  }
}

/// TextInputFormatter untuk memformat input nomor telepon secara real-time.
/// Mengubah input awal seperti "08...", "8...", "628..." menjadi "+62 8xx-xxxx-xxxx".
class IndonesianPhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Jika user menghapus semua teks
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Hanya ambil angka (dan + di awal jika ada)
    String rawText = newValue.text.replaceAll(RegExp(r'[^\d+]'), '');

    // Transformasi awal
    if (rawText.startsWith('0')) {
      rawText = '+62${rawText.substring(1)}';
    } else if (rawText.startsWith('8')) {
      rawText = '+62$rawText';
    } else if (rawText.startsWith('62')) {
      rawText = '+$rawText';
    } else if (!rawText.startsWith('+62') && rawText.isNotEmpty) {
      if (!rawText.startsWith('+')) {
        // Jika mulai dengan angka lain selain 0,8,62 (misal paste "123")
        // Biarkan saja atau paksakan +62? Kita asumsikan nomor Indo jadi paksa +62
        // Kecuali user sedang mengetik +...
        if (RegExp(r'^[1-579]').hasMatch(rawText)) {
          rawText = '+62$rawText';
        }
      }
    }

    // Ambil hanya angka dari rawText untuk diformat
    String digitsOnly = rawText.replaceAll(RegExp(r'[^\d]'), '');

    // Format digitsOnly ke: +62 XXX-XXXX-XXXX
    StringBuffer buffer = StringBuffer();
    if (digitsOnly.length >= 2) {
      // Pastikan prefix 62
      buffer.write('+${digitsOnly.substring(0, 2)} ');
      int index = 2;
      while (index < digitsOnly.length) {
        if (index == 2) {
          // Blok pertama setelah +62 (biasanya 3 digit awalan seperti 812)
          int end = (index + 3 <= digitsOnly.length) ? index + 3 : digitsOnly.length;
          buffer.write(digitsOnly.substring(index, end));
          index = end;
          if (index < digitsOnly.length) buffer.write('-');
        } else if (index == 5) {
          // Blok kedua (4 digit)
          int end = (index + 4 <= digitsOnly.length) ? index + 4 : digitsOnly.length;
          buffer.write(digitsOnly.substring(index, end));
          index = end;
          if (index < digitsOnly.length) buffer.write('-');
        } else {
          // Sisa digit
          buffer.write(digitsOnly.substring(index));
          break;
        }
      }
    } else if (digitsOnly.isNotEmpty) {
      buffer.write('+$digitsOnly');
    }

    String formattedText = buffer.toString();

    // Hitung posisi kursor (selalu taruh di akhir agar tidak pusing)
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}
