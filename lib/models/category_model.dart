import 'package:flutter/foundation.dart';

class CategoryModel {
  final String id;
  final String category;
  final String code;
  final String photoUrl;
  final List<String> subcategories;

  const CategoryModel({
    required this.id,
    required this.category,
    required this.code,
    required this.photoUrl,
    required this.subcategories,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      code: json['code'] as String? ?? '',
      photoUrl: json['photoUrl'] as String? ?? '',
      subcategories: List<String>.from(json['subcategories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'code': code,
      'photoUrl': photoUrl,
      'subcategories': subcategories,
    };
  }
}
