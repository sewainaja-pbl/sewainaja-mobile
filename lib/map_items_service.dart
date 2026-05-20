import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

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
      latitude: (coordinate['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (coordinate['longitude'] as num?)?.toDouble() ?? 0,
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

  Future<List<MapItem>> fetchNearbyItems({
    required double lat,
    required double lng,
    required int radiusKm,
    String? categoryId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw const MapItemsException('Token login tidak ditemukan.');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/items').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lng': lng.toString(),
        'radius': radiusKm.toString(),
        if (categoryId != null && categoryId.isNotEmpty) 'category': categoryId,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null || token.isEmpty) {
      throw const MapItemsException('Token login tidak ditemukan.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/categories'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
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
}

class MapItemsException implements Exception {
  final String message;
  const MapItemsException(this.message);
  @override
  String toString() => message;
}
