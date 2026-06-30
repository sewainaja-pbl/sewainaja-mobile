import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_feedback.dart';
import 'widgets/custom_app_bar.dart';

class LoginSecurityScreen extends StatefulWidget {
  const LoginSecurityScreen({super.key});

  @override
  State<LoginSecurityScreen> createState() => _LoginSecurityScreenState();
}

class _LoginSecurityScreenState extends State<LoginSecurityScreen> {
  static const String _keyLoginAlerts = 'security_login_alerts';
  static const String _keySessionReminder = 'security_session_reminder';
  static const String _keyRememberDevice = 'security_remember_device';

  bool _isLoading = true;
  bool _loginAlerts = true;
  bool _sessionReminder = true;
  bool _rememberDevice = true;

  // Deteksi apakah user login via email/password (bukan OAuth) agar tombol ganti password ditampilkan
  bool _isEmailPasswordUser = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _detectAuthProvider();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _loginAlerts = prefs.getBool(_keyLoginAlerts) ?? true;
      _sessionReminder = prefs.getBool(_keySessionReminder) ?? true;
      _rememberDevice = prefs.getBool(_keyRememberDevice) ?? true;
      _isLoading = false;
    });
  }

  void _detectAuthProvider() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final providers = user.providerData.map((p) => p.providerId).toList();
    setState(() {
      _isEmailPasswordUser = providers.contains('password');
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  /// Dialog untuk mengganti password via Firebase Auth
  Future<void> _showChangePasswordDialog() async {
    final currentPasswordCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: const Color(0xFFFFF8EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    const Text(
                      'Ganti Password',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Masukkan password lama Anda dan buat password baru yang kuat.',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF717973),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password lama
                    _buildPasswordField(
                      controller: currentPasswordCtrl,
                      label: 'Password Lama',
                      obscure: obscureCurrent,
                      onToggle: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                    const SizedBox(height: 12),

                    // Password baru
                    _buildPasswordField(
                      controller: newPasswordCtrl,
                      label: 'Password Baru',
                      obscure: obscureNew,
                      onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    const SizedBox(height: 12),

                    // Konfirmasi password baru
                    _buildPasswordField(
                      controller: confirmPasswordCtrl,
                      label: 'Konfirmasi Password Baru',
                      obscure: obscureConfirm,
                      onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    const SizedBox(height: 24),

                    // Tombol
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFC1C8C2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                color: Color(0xFF414844),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    final currentPw = currentPasswordCtrl.text.trim();
                                    final newPw = newPasswordCtrl.text.trim();
                                    final confirmPw = confirmPasswordCtrl.text.trim();

                                    if (currentPw.isEmpty || newPw.isEmpty || confirmPw.isEmpty) {
                                      showAppErrorSnack(context, 'Semua kolom harus diisi.');
                                      return;
                                    }
                                    if (newPw.length < 8) {
                                      showAppErrorSnack(context, 'Password baru minimal 8 karakter.');
                                      return;
                                    }
                                    if (newPw != confirmPw) {
                                      showAppErrorSnack(context, 'Konfirmasi password tidak cocok.');
                                      return;
                                    }

                                    setDialogState(() => isSubmitting = true);
                                    try {
                                      final user = FirebaseAuth.instance.currentUser;
                                      if (user == null || user.email == null) throw Exception('User tidak ditemukan');

                                      // Re-authenticate dulu sebelum ganti password
                                      final credential = EmailAuthProvider.credential(
                                        email: user.email!,
                                        password: currentPw,
                                      );
                                      await user.reauthenticateWithCredential(credential);
                                      await user.updatePassword(newPw);

                                      if (!dialogContext.mounted) return;
                                      Navigator.pop(dialogContext);

                                      if (mounted) {
                                        showAppSuccessSnack(context, 'Password berhasil diperbarui!');
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      String msg = 'Gagal mengganti password.';
                                      if (e.code == 'wrong-password') {
                                        msg = 'Password lama tidak benar.';
                                      } else if (e.code == 'weak-password') {
                                        msg = 'Password baru terlalu lemah.';
                                      } else if (e.code == 'too-many-requests') {
                                        msg = 'Terlalu banyak percobaan. Coba lagi nanti.';
                                      } else if (e.code == 'requires-recent-login') {
                                        msg = 'Sesi telah berakhir. Silakan login ulang.';
                                      }
                                      if (mounted) showAppErrorSnack(context, msg);
                                    } catch (e) {
                                      if (mounted) showAppErrorSnack(context, 'Terjadi kesalahan: ${e.toString()}');
                                    } finally {
                                      setDialogState(() => isSubmitting = false);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF012D1D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Simpan',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    currentPasswordCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmPasswordCtrl.dispose();
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 13,
        color: Color(0xFF012D1D),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          color: Color(0xFF717973),
        ),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 18,
            color: const Color(0xFF717973),
          ),
          onPressed: onToggle,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF012D1D)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      appBar: const CustomAppBar(
        title: 'Keamanan Login',
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF012D1D)),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 22),

                  // Ganti Password — hanya tampil jika login via email/password
                  if (_isEmailPasswordUser) ...[
                    _buildChangePasswordCard(),
                    const SizedBox(height: 22),
                  ],

                  _buildSection(
                    title: 'Proteksi Dasar',
                    description:
                        'Pengaturan ringan untuk membantu kamu tetap sadar dengan aktivitas login akun.',
                    children: [
                      _buildSwitchTile(
                        title: 'Peringatan saat login',
                        subtitle:
                            'Tampilkan pengingat ketika ada login baru atau aktivitas masuk yang penting.',
                        value: _loginAlerts,
                        onChanged: (value) async {
                          setState(() => _loginAlerts = value);
                          await _save(_keyLoginAlerts, value);
                        },
                        icon: Icons.notification_important_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Pengingat sesi aktif',
                        subtitle:
                            'Beri tahu saat sesi akun perlu dicek ulang atau login ulang.',
                        value: _sessionReminder,
                        onChanged: (value) async {
                          setState(() => _sessionReminder = value);
                          await _save(_keySessionReminder, value);
                        },
                        icon: Icons.manage_accounts_outlined,
                      ),
                      const SizedBox(height: 14),
                      _buildSwitchTile(
                        title: 'Ingat perangkat ini',
                        subtitle:
                            'Simpan preferensi dasar agar kamu tidak perlu terlalu sering mengatur ulang di perangkat ini.',
                        value: _rememberDevice,
                        onChanged: (value) async {
                          setState(() => _rememberDevice = value);
                          await _save(_keyRememberDevice, value);
                        },
                        icon: Icons.devices_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _buildSessionCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildChangePasswordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ganti Password',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Perbarui password akun Anda secara berkala untuk menjaga keamanan.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showChangePasswordDialog,
              icon: const Icon(Icons.lock_outline_rounded, size: 18),
              label: const Text(
                'Ganti Password Sekarang',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keamanan yang terasa tenang, bukan menegangkan.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Halaman ini membantu kamu menjaga kebiasaan login tetap aman, sambil menunggu kontrol keamanan yang lebih lengkap di tahap berikutnya.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F3),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0E4A31)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C1C19),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF717973),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF012D1D),
            activeTrackColor: const Color(0xFFBFD8CA),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan sesi',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF012D1D),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Saat ini sesi aktif terdeteksi di perangkat yang sedang kamu gunakan. Kalau nanti kita sudah punya manajemen sesi penuh, bagian ini bisa menampilkan riwayat perangkat dan aktivitas login terbaru.',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Color(0xFF717973),
            ),
          ),
        ],
      ),
    );
  }
}
