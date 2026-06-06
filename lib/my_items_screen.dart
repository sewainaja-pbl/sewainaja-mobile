import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models/item_model.dart';
import 'item_detail_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  List<Map<String, dynamic>> _displayItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final List<Map<String, dynamic>> dummyItems = [
      {
        "name": "Sony W830 with 8x Optical Zoom",
        "price": "Rp.120.000/Day",
        "rating": "4.8(292)",
        "image": "assets/images/Iklan.jpg",
        "more_options": true,
      },
      {
        "name": "Sony Dual-Sense PS5",
        "price": "Rp.45.000/Day",
        "rating": "4.8(292)",
        "image": "assets/images/Iklan.jpg",
        "more_options": true,
      },
      {
        "name": "Sony Dual-Sense PS5 (Baris Baru)",
        "price": "Rp.45.000/Day",
        "rating": "4.8(292)",
        "image": "assets/images/Iklan.jpg",
        "more_options": true,
      },
    ];

    try {
      final prefs = await SharedPreferences.getInstance();
      final localItemsStr = prefs.getString('local_user_items') ?? '[]';
      final List<dynamic> localItemsDynamic = jsonDecode(localItemsStr);
      final List<Map<String, dynamic>> localItems = List<Map<String, dynamic>>.from(localItemsDynamic);
      
      setState(() {
        _displayItems = [...localItems, ...dummyItems];
      });
    } catch (e) {
      debugPrint('Failed to load local items: $e');
      setState(() {
        _displayItems = dummyItems;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Krem Terang
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDF9F4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF012D1D)),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "Barang Saya",
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 30, // Updated size based on spec
            fontWeight: FontWeight.w600,
            color: Color(0xFF1B4332), // Hijau Medium
          ),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(24.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.70, // Menyesuaikan agar text dan gambar proporsional
        ),
        itemCount: _displayItems.length,
        itemBuilder: (context, index) {
          final item = _displayItems[index];
          return _buildItemCard(item);
        },
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    // Check if the image is a local file or asset
    final isLocalAsset = item['isLocalAsset'] == true;
    final imageProvider = isLocalAsset 
        ? FileImage(File(item["image"])) as ImageProvider
        : AssetImage(item["image"]);

    return GestureDetector(
      onTap: () {
        ItemModel? lightweightItem;
        try {
          String priceStr = item["price"].toString();
          String unit = "Hari";
          if (priceStr.toLowerCase().contains("hour") || priceStr.toLowerCase().contains("jam")) {
            unit = "Jam";
          } else if (priceStr.toLowerCase().contains("week") || priceStr.toLowerCase().contains("minggu")) {
            unit = "Minggu";
          }
          double parsedPrice = double.parse(priceStr.replaceAll(RegExp(r'[^0-9]'), ''));
          double computedPricePerHour = unit == "Jam" ? parsedPrice : (unit == "Minggu" ? parsedPrice / 168 : parsedPrice / 24);
          
          lightweightItem = ItemModel(
            id: item['id']?.toString() ?? '',
            ownerId: '',
            ownerName: item['owner']?.toString() ?? 'Owner',
            ownerRating: 4.8,
            categoryId: '',
            categoryName: '',
            name: item['name'],
            description: '',
            pricePerHour: computedPricePerHour,
            price: parsedPrice,
            priceUnit: unit,
            status: 'available',
            condition: 'fair',
            photos: [item['image']],
          );
        } catch (_) {}
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(
              itemName: item["name"],
              sellerLocation: "Semarang",
              imagePath: item["image"],
              isLocalAsset: item['isLocalAsset'] == true,
              item: lightweightItem,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF2F6743), // Outline Hijau SewaInAja
            width: 0.5,
          ),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Rating Badge
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000000).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFF8BD00),
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item["rating"],
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFFF8EF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Details Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item["name"],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500, // Medium
                    color: Color(0xFF414844),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item["price"],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w700, // Bold
                          color: Color(0xFF414844),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item["more_options"] == true)
                      GestureDetector(
                        onTap: () {
                          // TODO: Action for context menu (edit/delete)
                        },
                        child: const Icon(
                          Icons.more_vert_rounded,
                          size: 18,
                          color: Color(0xFF414844),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ));
  }
}
