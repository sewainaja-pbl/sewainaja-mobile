class ProductData {
  final String? id;
  final String name;
  final String price;
  final dynamic rating;
  final String image;

  ProductData({
    this.id,
    required this.name,
    required this.price,
    required this.rating,
    required this.image,
  });
}
