import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'auth_session_service.dart';

class CachedUserProfile {
  final String name;
  final String email;
  final String phone;
  final String profilePhotoUrl;
  final String status;

  const CachedUserProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.profilePhotoUrl,
    required this.status,
  });

  factory CachedUserProfile.fromPrefs(SharedPreferences prefs) {
    return CachedUserProfile(
      name: prefs.getString('user_name')?.trim() ?? '',
      email: prefs.getString('user_email')?.trim() ?? '',
      phone: prefs.getString('user_phone')?.trim() ?? '',
      profilePhotoUrl: prefs.getString('user_profile_photo_url')?.trim() ?? '',
      status: prefs.getString('user_status')?.trim() ?? '',
    );
  }

  factory CachedUserProfile.fromJson(Map<String, dynamic> json) {
    return CachedUserProfile(
      name: (json['name'] ?? '').toString().trim(),
      email: (json['email'] ?? '').toString().trim(),
      phone: (json['phone'] ?? '').toString().trim(),
      profilePhotoUrl: (json['profilePhotoUrl'] ?? '').toString().trim(),
      status: (json['status'] ?? '').toString().trim(),
    );
  }

  String get displayName => name;
  String get displayEmail => email;
  String get displayPhone => phone;
  bool get isVerified => status.toLowerCase() == 'verified';
  bool get isPendingVerification => status.toLowerCase() == 'pending';
}

class ProfileSyncService {
  const ProfileSyncService({
    AuthSessionService authSessionService = const AuthSessionService(),
  }) : _authSessionService = authSessionService;

  static final ValueNotifier<int> profileRevision = ValueNotifier<int>(0);

  final AuthSessionService _authSessionService;

  Future<CachedUserProfile> readCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return CachedUserProfile.fromPrefs(prefs);
  }

  Future<CachedUserProfile?> syncProfileFromApi({
    bool forceRefreshToken = true,
  }) async {
    final token = await _authSessionService.getValidIdToken(
      forceRefresh: forceRefreshToken,
    );
    if (token == null || token.isEmpty) {
      return null;
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      return null;
    }

    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      return null;
    }

    final profile = CachedUserProfile.fromJson(data);
    await saveProfileToCache(profile, notify: true);
    return profile;
  }

  Future<void> saveProfileToCache(
    CachedUserProfile profile, {
    bool notify = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', profile.name);
    await prefs.setString('user_email', profile.email);
    await prefs.setString('user_phone', profile.phone);
    await prefs.setString('user_profile_photo_url', profile.profilePhotoUrl);
    await prefs.setString('user_status', profile.status);
    if (notify) {
      profileRevision.value++;
    }
  }
}
