import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../controllers/auth_controller.dart';
import '../../../app_feedback.dart';
import '../../../api_config.dart';
import '../../../notification_service.dart';
import '../../../main_navigation_screen.dart';
import '../../../profile_setup_screen.dart';
import '../../../core/utils/phone_formatter.dart';

/// Data yang dibutuhkan untuk menyelesaikan alur REGISTRASI setelah OTP.
class OtpRegisterData {
  final String name;
  final String email;
  final String password;
  final String phone;

  const OtpRegisterData({
    required this.name,
    required this.email,
    required this.password,
    required this.phone,
  });
}

/// Data yang dibutuhkan untuk menyelesaikan alur LOGIN setelah OTP.
class OtpLoginData {
  final String uid;
  final String idToken;

  const OtpLoginData({required this.uid, required this.idToken});
}

/// Halaman verifikasi OTP.
///
/// Menerima [flowType] untuk menentukan aksi setelah OTP sukses:
/// - [AuthFlowType.register]: buat akun Firebase + buat dokumen Firestore
/// - [AuthFlowType.login]: konfirmasi OTP + masuk ke home
///
/// Fitur:
/// - 6 kotak OTP dengan auto-focus & auto-submit
/// - Countdown timer 60 detik
/// - Tombol RESEND aktif setelah timer habis
/// - Masking nomor HP yang ditampilkan
/// - Auto-verification Android via verificationCompleted callback
class OtpPage extends StatefulWidget {
  final String phoneNumber;
  final AuthFlowType flowType;
  final OtpRegisterData? registerData;
  final OtpLoginData? loginData;

  const OtpPage({
    super.key,
    required this.phoneNumber,
    required this.flowType,
    this.registerData,
    this.loginData,
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  // Controllers untuk 6 slot OTP
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  // Countdown timer
  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _setupAutoVerification();
    // Fokus ke slot pertama saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
          _canResend = true;
        });
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  /// Setup auto-verification untuk Android (SMS otomatis terdeteksi).
  void _setupAutoVerification() {
    final authController = context.read<AuthController>();
    // Kirim ulang OTP dengan handler auto-verification yang akan langsung submit
    authController.sendOtp(
      phoneNumber: widget.phoneNumber,
      onAutoVerified: (PhoneAuthCredential credential) {
        // Android berhasil auto-detect SMS — langsung proses tanpa user input
        if (mounted) {
          _processAutoVerification(credential);
        }
      },
    );
  }

  /// Proses auto-verification dari Android.
  Future<void> _processAutoVerification(
      PhoneAuthCredential credential) async {
    setState(() => _isVerifying = true);
    try {
      if (widget.flowType == AuthFlowType.register &&
          widget.registerData != null) {
        // Untuk register: buat akun dengan email/password lalu link HP
        final userCred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: widget.registerData!.email,
              password: widget.registerData!.password,
            );
        await userCred.user!.linkWithCredential(credential);
        await _finalizeRegistration(userCred.user!.uid);
      } else if (widget.flowType == AuthFlowType.login) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.reauthenticateWithCredential(credential);
          await _finalizeLogin();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        showAppErrorSnack(context, 'Auto-verifikasi gagal. Masukkan kode OTP manual.');
      }
    }
  }

  String get _otpCode =>
      _controllers.map((c) => c.text).join();

  /// Format timer menjadi M:SS.
  String get _timerDisplay {
    final minutes = _secondsRemaining ~/ 60;
    final seconds = _secondsRemaining % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _handleResend() async {
    if (!_canResend || _isVerifying) return;

    // Bersihkan semua input
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();

    final authController = context.read<AuthController>();
    showAppSuccessSnack(
      context,
      'Mengirim ulang OTP ke ${PhoneFormatter.maskPhone(widget.phoneNumber)}...',
    );

    final sent = await authController.sendOtp(
      phoneNumber: widget.phoneNumber,
      onAutoVerified: _processAutoVerification,
    );

    if (!mounted) return;

    if (sent) {
      showAppSuccessSnack(context, 'OTP berhasil dikirim ulang!');
      _startTimer();
    } else {
      showAppErrorSnack(
        context,
        authController.errorMessage ?? 'Gagal kirim ulang OTP.',
      );
    }
  }

  Future<void> _handleVerify() async {
    final code = _otpCode;
    if (code.length < 6) {
      showAppErrorSnack(context, 'Masukkan 6 digit kode OTP.');
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final authController = context.read<AuthController>();

      if (widget.flowType == AuthFlowType.register) {
        await _handleRegisterVerify(authController, code);
      } else {
        await _handleLoginVerify(authController, code);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  /// Verifikasi OTP untuk alur REGISTRASI.
  Future<void> _handleRegisterVerify(
      AuthController authController, String code) async {
    if (widget.registerData == null) {
      showAppErrorSnack(context, 'Data registrasi tidak lengkap.');
      return;
    }

    final credential = await authController.verifyOtpAndSignUp(
      otpCode: code,
      email: widget.registerData!.email,
      password: widget.registerData!.password,
    );

    if (!mounted) return;

    if (credential == null) {
      showAppErrorSnack(
        context,
        authController.errorMessage ?? 'Verifikasi OTP gagal.',
      );
      return;
    }

    // OTP berhasil — selesaikan registrasi via backend
    await _finalizeRegistration(credential.user!.uid);
  }

  /// Verifikasi OTP untuk alur LOGIN.
  Future<void> _handleLoginVerify(
      AuthController authController, String code) async {
    final credential = await authController.verifyOtpAndLogin(otpCode: code);

    if (!mounted) return;

    if (credential == null) {
      showAppErrorSnack(
        context,
        authController.errorMessage ?? 'Verifikasi OTP gagal.',
      );
      return;
    }

    await _finalizeLogin();
  }

  /// Buat dokumen Firestore user via backend setelah registrasi sukses.
  Future<void> _finalizeRegistration(String uid) async {
    final authController = context.read<AuthController>();
    final data = widget.registerData!;

    final success = await authController.completeRegistration(
      uid: uid,
      name: data.name,
      email: data.email,
      phone: data.phone,
    );

    if (!mounted) return;

    if (!success) {
      showAppErrorSnack(
        context,
        authController.errorMessage ?? 'Gagal menyelesaikan pendaftaran.',
      );
      return;
    }

    showAppSuccessSnack(context, 'Akun berhasil dibuat!');

    // Simpan data minimal ke SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final idToken =
        await FirebaseAuth.instance.currentUser?.getIdToken();
    await prefs.setString('token', idToken ?? '');
    await prefs.setString('user_id', uid);
    await prefs.setString('user_name', data.name);
    await prefs.setString('user_email', data.email);
    await prefs.setString('user_phone', data.phone);
    await prefs.setBool('onboarding_seen', true);

    if (!mounted) return;

    // Redirect ke ProfileSetupScreen (status user = "pending")
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      (route) => false,
    );
  }

  /// Simpan data sesi dan navigasi ke home setelah login sukses.
  Future<void> _finalizeLogin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final idToken = await user.getIdToken();

      // Ambil profil lengkap dari backend
      final profileResponse = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', idToken ?? '');
      await prefs.setString('user_id', user.uid);
      await prefs.setBool('onboarding_seen', true);

      if (profileResponse.statusCode == 200) {
        final respData =
            jsonDecode(profileResponse.body) as Map<String, dynamic>;
        final userData = respData['data'] as Map<String, dynamic>? ?? {};
        await prefs.setString('user_name', userData['name']?.toString() ?? '');
        await prefs.setString('user_email', userData['email']?.toString() ?? '');
        await prefs.setString('user_phone', userData['phone']?.toString() ?? '');
        await prefs.setString(
          'user_profile_photo_url',
          userData['profilePhotoUrl']?.toString() ?? '',
        );
        await prefs.setString(
            'user_status', userData['status']?.toString() ?? '');
      }

      await NotificationService.instance.syncAfterLogin();

      if (!mounted) return;
      showAppSuccessSnack(context, 'Login berhasil!');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Gagal memuat profil. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    final maskedPhone = PhoneFormatter.maskPhone(widget.phoneNumber);
    final title = widget.flowType == AuthFlowType.register
        ? 'Verifikasi Registrasi'
        : 'Verifikasi Login';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Tombol back
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _isVerifying
                                ? null
                                : () {
                                    context.read<AuthController>().resetOtpState();
                                    Navigator.pop(context);
                                  },
                            child: Icon(
                              Icons.arrow_back,
                              color: _isVerifying
                                  ? const Color(0xFF012D1D).withValues(alpha: 0.4)
                                  : const Color(0xFF012D1D),
                            ),
                          ),
                        ),

                        const Spacer(flex: 2),

                        // Ilustrasi
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: isKeyboardOpen ? 0 : screenHeight * 0.25,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: isKeyboardOpen ? 0.0 : 1.0,
                              child: Image.asset(
                                'assets/images/otp_illustration.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Judul
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF012D1D),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),

                        // Instruksi dengan nomor HP yang di-mask
                        Text(
                          'Masukkan 6 digit kode OTP yang dikirim ke\n$maskedPhone',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            color: Color(0xFF414844),
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const Spacer(flex: 2),

                        // 6 Kotak OTP
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 48,
                              height: 56,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                textAlignVertical: TextAlignVertical.center,
                                maxLength: 1,
                                enabled: !_isVerifying,
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
                                  counterText: '',
                                  contentPadding: EdgeInsets.zero,
                                  filled: true,
                                  fillColor: Colors.white,
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
                                      width: 2.5,
                                    ),
                                  ),
                                  disabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                      color: const Color(0xFF7B5804)
                                          .withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty && index < 5) {
                                    _focusNodes[index + 1].requestFocus();
                                  } else if (value.isEmpty && index > 0) {
                                    _focusNodes[index - 1].requestFocus();
                                  }
                                  // Auto-submit jika semua kotak terisi
                                  if (_otpCode.length == 6 && !_isVerifying) {
                                    _handleVerify();
                                  }
                                },
                              ),
                            );
                          }),
                        ),

                        const Spacer(flex: 2),

                        // Timer countdown
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _canResend
                              ? const SizedBox.shrink()
                              : Text(
                                  _timerDisplay,
                                  key: ValueKey(_secondsRemaining),
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF414844),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),

                        // Tombol RESEND
                        GestureDetector(
                          onTap: (_canResend && !_isVerifying)
                              ? _handleResend
                              : null,
                          child: Text.rich(
                            TextSpan(
                              text: 'Kirim ulang OTP? ',
                              children: [
                                TextSpan(
                                  text: 'RESEND',
                                  style: TextStyle(
                                    color: _canResend && !_isVerifying
                                        ? const Color(0xFF7B5804)
                                        : const Color(0xFF7B5804)
                                            .withValues(alpha: 0.4),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: (_canResend && !_isVerifying)
                                  ? const Color(0xFF414844)
                                  : const Color(0xFF414844)
                                      .withValues(alpha: 0.5),
                            ),
                          ),
                        ),

                        const Spacer(flex: 3),

                        // Tombol Konfirmasi
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isVerifying ? null : _handleVerify,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7B5804),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF7B5804).withValues(alpha: 0.6),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              elevation: 0,
                            ),
                            child: _isVerifying
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Konfirmasi OTP',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
