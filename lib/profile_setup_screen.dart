import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'app_feedback.dart';
import 'auth_session_service.dart';
import 'default_address_setup_screen.dart';
import 'image_upload_service.dart';
import 'upload_image_policy.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final ImageUploadService _imageUploadService = ImageUploadService();
  final AuthSessionService _authSessionService = const AuthSessionService();
  ProcessedImageFile? _pendingProfilePhoto;
  String _profilePhotoUrl = '';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadStoredPhoto();
  }

  Future<void> _loadStoredPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('user_profile_photo_url') ?? '';
    if (!mounted || saved.isEmpty) return;
    setState(() {
      _profilePhotoUrl = saved;
    });
  }

  Future<void> _pickProfilePhoto() async {
    try {
      final sourceChoice = await _imageUploadService.chooseImageSource(context);
      if (sourceChoice == null) return;
      final picked = await _imageUploadService.pickSingleImageFromSource(
        policy: UploadImagePolicy.profile,
        source: sourceChoice == ImageSourceChoice.camera
            ? ImageSource.camera
            : ImageSource.gallery,
      );
      if (picked == null || !mounted) return;
      setState(() {
        _pendingProfilePhoto = picked;
      });
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnack(context, safeImageError(error));
    }
  }

  Future<void> _continueToAddressSetup() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await _authSessionService.getValidIdToken(forceRefresh: true) ?? '';
      final userId = prefs.getString('user_id')?.trim() ?? '';
      var finalPhotoUrl = _profilePhotoUrl;

      if (_pendingProfilePhoto != null) {
        if (userId.isEmpty) {
          if (!mounted) return;
          showAppErrorSnack(context, 'User ID belum tersedia. Ulangi registrasi atau login ulang.');
          return;
        }
        finalPhotoUrl = await _imageUploadService.uploadProcessedImage(
          processed: _pendingProfilePhoto!,
          storagePath: _imageUploadService.buildUserAvatarStoragePath(userId),
        );
        await prefs.setString('user_profile_photo_url', finalPhotoUrl);
      }

      if (token.isNotEmpty && finalPhotoUrl.isNotEmpty) {
        final response = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'profilePhotoUrl': finalPhotoUrl}),
        );
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (response.statusCode != 200 || body['success'] != true) {
          if (!mounted) return;
          final message =
              body['error']?['message']?.toString() ?? 'Gagal menyimpan foto profil.';
          showAppErrorSnack(
            context,
            message.toLowerCase().contains('token')
                ? 'Sesi login sudah tidak valid. Silakan login ulang.'
                : message,
          );
          return;
        }
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const DefaultAddressSetupScreen(),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      showAppErrorSnack(context, safeImageError(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  ImageProvider _resolvedImage() {
    if (_pendingProfilePhoto != null) {
      return _imageUploadService.buildProcessedImageProvider(_pendingProfilePhoto!);
    }
    if (_profilePhotoUrl.trim().isNotEmpty) {
      return _imageUploadService.buildImageProvider(_profilePhotoUrl, targetWidth: 320);
    }
    return const AssetImage('assets/images/profile_user.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              const Text(
                'Atur Foto Profil',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF012D1D),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Foto akan disanitasi ke ${UploadImagePolicy.profile.sizeLabelMb} MB supaya avatar tetap ringan dan tajam.',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF414844),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 52),
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _isSubmitting ? null : _pickProfilePhoto,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD9D9D9),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image(
                            image: _resolvedImage(),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Center(
                              child: Icon(
                                Icons.camera_alt,
                                size: 60,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: _isSubmitting ? null : _pickProfilePhoto,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF7B5804),
                              width: 2.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 24,
                            color: Color(0xFF7B5804),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Opsional sekarang, bisa diganti lagi nanti di Edit Profil.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Color(0xFF5C635E),
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _continueToAddressSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7B5804),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    elevation: 0,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFFFFF),
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
