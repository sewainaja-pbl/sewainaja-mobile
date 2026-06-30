import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session_service.dart';

class UserAddress {
  final String id;
  final String label;
  final String fullAddress;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const UserAddress({
    required this.id,
    required this.label,
    required this.fullAddress,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  factory UserAddress.fromJson(Map<String, dynamic> json) {
    final coordinate = (json['coordinat'] as Map<String, dynamic>?) ?? const {};
    final lat =
        (coordinate['latitude'] ?? coordinate['_latitude'] ?? coordinate['lat']) as num?;
    final lng =
        (coordinate['longitude'] ?? coordinate['_longitude'] ?? coordinate['lng']) as num?;
    return UserAddress(
      id: (json['id'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      fullAddress: (json['fullAddress'] ?? '').toString(),
      isDefault: json['isDefault'] == true,
      latitude: lat?.toDouble(),
      longitude: lng?.toDouble(),
    );
  }
}

class AddressService {
  const AddressService();

  static const AuthSessionService _authSessionService = AuthSessionService();

  Future<List<UserAddress>> fetchAddresses() async {
    final token = await _readToken();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/addresses'),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw AddressServiceException(
        body['error']?['message']?.toString() ?? 'Gagal mengambil data alamat.',
      );
    }

    final raw = (body['data'] as List<dynamic>? ?? const []);
    return raw
        .whereType<Map>()
        .map((item) => item.map(
              (key, value) => MapEntry(key.toString(), value),
            ))
        .map(UserAddress.fromJson)
        .toList();
  }

  Future<UserAddress?> fetchDefaultAddress() async {
    final addresses = await fetchAddresses();
    if (addresses.isEmpty) return null;
    for (final address in addresses) {
      if (address.isDefault) return address;
    }
    return addresses.first;
  }

  Future<void> upsertDefaultAddress({
    required String label,
    required String fullAddress,
    required double latitude,
    required double longitude,
  }) async {
    final token = await _readToken();
    final addresses = await fetchAddresses();

    UserAddress? matched;
    for (final address in addresses) {
      final lat = address.latitude;
      final lng = address.longitude;
      if (lat == null || lng == null) continue;
      final meter = Geolocator.distanceBetween(latitude, longitude, lat, lng);
      if (meter <= 30) {
        matched = address;
        break;
      }
    }

    if (matched != null) {
      await _setDefaultAddress(token, matched.id);
      return;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/addresses'),
      headers: _headers(token),
      body: jsonEncode({
        'label': label,
        'fullAddress': fullAddress,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': true,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw AddressServiceException(
        body['error']?['message']?.toString() ?? 'Gagal menyimpan alamat default.',
      );
    }
  }

  Future<void> _setDefaultAddress(String token, String id) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/addresses/$id/default'),
      headers: _headers(token),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200 || body['success'] != true) {
      throw AddressServiceException(
        body['error']?['message']?.toString() ?? 'Gagal set alamat default.',
      );
    }
  }

  Future<String> _readToken() async {
    final token = await _authSessionService.getValidIdToken(forceRefresh: true);
    if (token == null || token.isEmpty) {
      throw const AddressServiceException('Token login tidak ditemukan.');
    }
    return token;
  }

  Map<String, String> _headers(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }
}

class AddressServiceException implements Exception {
  final String message;
  const AddressServiceException(this.message);

  @override
  String toString() => message;
}
