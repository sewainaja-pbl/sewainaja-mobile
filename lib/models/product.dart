import '../data/models/item_model.dart';

class ProductData {
  final String? id;
  final String name;
  final String price;
  final dynamic rating;
  final String image;
  final bool isLocalAsset;
  final ItemModel? originalItem;

  ProductData({
    this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.image,
    this.isLocalAsset = false,
    this.originalItem,
  });
}
