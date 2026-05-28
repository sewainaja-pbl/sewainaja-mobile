import 'package:cloud_firestore/cloud_firestore.dart';

/// Model untuk document di collection `items/{itemId}` di Firestore.
/// Mengikuti schema yang didefinisikan di DATABASE.md.
class ItemModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final double ownerRating;
  final String categoryId;
  final String categoryName;
  final String name;
  final String description;
  final double pricePerHour;
  final String status; // "available" | "inactive" | "archived" | "blocked"
  final String condition; // "new" | "like-new" | "fair" | "poor"
  final List<String> photos; // index 0 = foto utama
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ItemModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerRating,
    required this.categoryId,
    required this.categoryName,
    required this.name,
    required this.description,
    required this.pricePerHour,
    required this.status,
    required this.condition,
    required this.photos,
    this.createdAt,
    this.updatedAt,
  });

  /// Foto utama (index 0), atau string kosong jika tidak ada foto.
  String get primaryPhoto => photos.isNotEmpty ? photos[0] : '';

  /// Harga formatted dalam Rupiah per hari (pricePerHour * 24).
  String get formattedPricePerDay {
    final daily = pricePerHour * 24;
    final formatted = daily
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
    return 'Rp.$formatted';
  }

  factory ItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ItemModel(
      id: doc.id,
      ownerId: data['ownerId'] as String? ?? '',
      ownerName: data['ownerName'] as String? ?? '',
      ownerRating: (data['ownerRating'] as num?)?.toDouble() ?? 0.0,
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'available',
      condition: data['condition'] as String? ?? 'fair',
      photos: List<String>.from(data['photos'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'ownerName': ownerName,
    'ownerRating': ownerRating,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'name': name,
    'description': description,
    'pricePerHour': pricePerHour,
    'status': status,
    'condition': condition,
    'photos': photos,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };
}
