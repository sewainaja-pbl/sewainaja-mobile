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
