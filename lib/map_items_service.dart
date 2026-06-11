import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_session_service.dart';

class MapItem {
  final String id;
  final String name;
  final String categoryId;
  final double pricePerHour;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final String categoryName;
  final String photoUrl;

  const MapItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.pricePerHour,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.categoryName,
    required this.photoUrl,
  });

  factory MapItem.fromJson(Map<String, dynamic> json) {
    final address = (json['address'] as Map<String, dynamic>?) ?? {};
    final coordinate = (address['coordinat'] as Map<String, dynamic>?) ?? {};
    final photos = (json['photos'] as List<dynamic>?) ?? const [];
    final firstPhoto = photos.isNotEmpty ? photos.first.toString() : '';
    return MapItem(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? 'Unnamed Item').toString(),
      categoryId: (json['categoryId'] ?? '').toString(),
      pricePerHour: (json['pricePerHour'] as num?)?.toDouble() ?? 0,
      latitude: ((coordinate['latitude'] ?? coordinate['_latitude'] ?? coordinate['lat']) as num?)?.toDouble() ?? 0,
      longitude: ((coordinate['longitude'] ?? coordinate['_longitude'] ?? coordinate['lng']) as num?)?.toDouble() ?? 0,
      distanceKm: (json['distance'] as num?)?.toDouble() ?? 0,
      categoryName: (json['categoryName'] ?? '').toString(),
      photoUrl: firstPhoto,
    );
  }
}

class MapCategory {
  final String id;
  final String label;

  const MapCategory({
    required this.id,
    required this.label,
  });
}

class MapItemsService {
  const MapItemsService();

  static const AuthSessionService _authSessionService = AuthSessionService();

  Future<List<MapItem>> fetchNearbyItems({
    required double lat,
    required double lng,
    required int radiusKm,
    String? categoryId,
  }) async {
    final token = await _authSessionService.getValidIdToken();

    final uri = Uri.parse('${ApiConfig.baseUrl}/items').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radiusKm.toString(),
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
      },
    );

    http.Response response;
    try {
      response = await http
          .get(uri, headers: _buildHeaders(token))
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const MapItemsException('Request map timeout. Coba lagi sebentar.');
    } catch (_) {
      throw const MapItemsException('Koneksi ke layanan map gagal.');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const MapItemsException('Respons data map tidak valid.');
    }
    if (response.statusCode != 200 || body['success'] != true) {
      throw MapItemsException(
        body['error']?['message']?.toString() ??
            'Gagal memuat barang terdekat.',
      );
    }

    final rawList = (body['data'] as List<dynamic>? ?? const []);
    return rawList
        .map((item) => MapItem.fromJson(item as Map<String, dynamic>))
        .where((item) => item.latitude != 0 && item.longitude != 0)
        .toList();
  }

  Future<List<MapCategory>> fetchCategories() async {
    final token = await _authSessionService.getValidIdToken();

    http.Response response;
    try {
      response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/categories'),
            headers: _buildHeaders(token),
          )
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      throw const MapItemsException('Request kategori timeout.');
    } catch (_) {
      throw const MapItemsException('Koneksi ke layanan kategori gagal.');
    }

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const MapItemsException('Respons kategori tidak valid.');
    }
    if (response.statusCode != 200 || body['success'] != true) {
      throw MapItemsException(
        body['error']?['message']?.toString() ?? 'Gagal memuat kategori.',
      );
    }

    final raw = (body['data'] as List<dynamic>? ?? const []);
    return raw
        .whereType<Map<String, dynamic>>()
        .map(
          (cat) => MapCategory(
            id: (cat['id'] ?? '').toString(),
            label: (cat['category'] ?? 'Kategori').toString(),
          ),
        )
        .where((cat) => cat.id.isNotEmpty)
        .toList();
  }

  Map<String, String> _buildHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}

class MapItemsException implements Exception {
  final String message;
  const MapItemsException(this.message);
  @override
  String toString() => message;
}
