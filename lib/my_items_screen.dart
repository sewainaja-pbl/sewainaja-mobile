import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/models/item_model.dart';
import 'item_detail_screen.dart';
import 'main_navigation_screen.dart';
import 'widgets/product_more_sheet.dart';
import 'models/product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product_screen.dart';
import 'package:http/http.dart' as http;
import 'auth_session_service.dart';
import 'api_config.dart';
import 'app_feedback.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  List<Map<String, dynamic>> _displayItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await const AuthSessionService().getValidIdToken();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/items/mine'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'] ?? [];
        
        final List<Map<String, dynamic>> fetchedItems = data.map((item) {
          final photos = item['photos'] as List<dynamic>? ?? [];
          final String imageUrl = photos.isNotEmpty ? photos[0].toString() : '';
          
          return {
            'id': item['id'],
            'name': item['name'] ?? 'Tanpa Nama',
            'price': 'Rp ${item['price'] ?? 0}/${item['priceUnit'] ?? 'Hari'}',
            'image': imageUrl,
            'isLocalAsset': false,
            'rating': (item['ownerRating'] ?? 0).toString(),
            'owner': item['ownerName'] ?? 'Owner',
            'status': item['status'] ?? 'available',
            'rawPrice': item['price'],
            'rawPriceUnit': item['priceUnit'],
          };
        }).toList();

        setState(() {
          _displayItems = fetchedItems;
          _isLoading = false;
        });

        // Simpan cache ke lokal
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('local_user_items', jsonEncode(fetchedItems));
      } else {
        // Fallback to local
        final prefs = await SharedPreferences.getInstance();
        final localItemsStr = prefs.getString('local_user_items') ?? '[]';
        setState(() {
          _displayItems = List<Map<String, dynamic>>.from(jsonDecode(localItemsStr));
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load items from API: $e');
      final prefs = await SharedPreferences.getInstance();
      final localItemsStr = prefs.getString('local_user_items') ?? '[]';
      setState(() {
        _displayItems = List<Map<String, dynamic>>.from(jsonDecode(localItemsStr));
        _isLoading = false;
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
      extendBody: true,
      body: Stack(
        children: [
          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF012D1D)))
            : _displayItems.isEmpty 
              ? const Center(
                  child: Text(
                    "Belum ada barang yang didaftarkan",
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF828282),
                    ),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0), // Added bottom padding for navbar
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
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          height: 75,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF012D1D),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(index: 0, activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined),
              _buildNavItem(index: 1, activeIcon: Icons.grid_view_rounded, inactiveIcon: Icons.grid_view_outlined),
              _buildNavItem(index: 2, activeIcon: Icons.add_box_rounded, inactiveIcon: Icons.add_box_outlined),
              _buildNavItem(index: 3, activeIcon: Icons.chat_bubble_rounded, inactiveIcon: Icons.chat_bubble_outline_rounded),
              _buildNavItem(index: 4, activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData activeIcon, required IconData inactiveIcon}) {
    final bool isActive = 4 == index; // Profile is always active in MyItemsScreen

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          Navigator.pop(context); // Go back to profile screen
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(initialIndex: index),
            ),
            (route) => false,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF8EF) : const Color(0xFF1B4332),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Icon(
              isActive ? activeIcon : inactiveIcon,
              key: ValueKey<bool>(isActive),
              color: isActive ? const Color(0xFF012D1D) : const Color(0xFFFFF8EF),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final isLocalAsset = item['isLocalAsset'] == true;
    final hasImage = item["image"] != null && item["image"].toString().isNotEmpty;
    final status = item['status']?.toString() ?? 'available';
    final isArchived = status == 'archived';
    final isInactive = status == 'inactive';
    final isDisabled = isArchived || isInactive;

    final imageProvider = hasImage
        ? (isLocalAsset 
            ? FileImage(File(item["image"])) as ImageProvider
            : NetworkImage(item["image"])) // Use NetworkImage if not local asset
        : null;

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
        foregroundDecoration: isDisabled
            ? BoxDecoration(
                color: Colors.white.withOpacity(0.5), // Efek abu-abu
                borderRadius: BorderRadius.circular(15),
              )
            : null,
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDisabled ? const Color(0xFFBDBDBD) : const Color(0xFF2F6743), // Outline abu-abu jika disabled
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
                      color: Colors.grey.shade200,
                      image: imageProvider != null
                          ? DecorationImage(
                              image: imageProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageProvider == null
                        ? const Center(
                            child: Icon(
                              Icons.image_outlined,
                              color: Color(0xFF828282),
                              size: 36,
                            ),
                          )
                        : null,
                  ),

                  // Badge for status (Archived / Blocked)
                  if (isDisabled)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isArchived ? const Color(0xFFE33629) : const Color(0xFF828282),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isArchived ? "DIARSIPKAN" : "DIBLOKIR",
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Rating Badge (hidden if disabled for cleaner look, or just keep it under the overlay)
                  if (!isDisabled)
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
                      GestureDetector(
                        onTap: () {
                          // Prevent interactions if archived/blocked
                          // Or we can still allow viewing/editing but maybe restrict deletion
                          // Actually, user should still be able to open the menu to edit/restore if we had such feature.
                          final productData = ProductData(
                            id: item['id']?.toString() ?? '',
                            name: item['name']?.toString() ?? '',
                            price: item['price']?.toString() ?? '',
                            rating: item['rating']?.toString() ?? '4.8',
                            image: item['image']?.toString() ?? '',
                            isLocalAsset: item['isLocalAsset'] == true,
                          );
                          showProductMoreSheet(
                            context: context,
                            product: productData,
                            onFavoritePressed: () {},
                            onSimilarPressed: () {},
                            onNotInterestedPressed: () {},
                            onReportPressed: () {},
                            onEditPressed: () {
                              if (isArchived) {
                                showAppErrorSnack(context, 'Barang yang diarsipkan tidak dapat diedit.');
                                return;
                              }
                              final itemId = item['id']?.toString() ?? '';
                              if (itemId.isEmpty) {
                                showAppErrorSnack(context, 'Barang simulasi tidak dapat diedit.');
                                return;
                              }
                              ItemModel? itemModel;
                              try {
                                double parsedPrice = double.tryParse(item['rawPrice']?.toString() ?? '0') ?? 0;
                                String unit = item['rawPriceUnit']?.toString() ?? "Hari";
                                double computedPricePerHour = unit.toLowerCase() == "jam" ? parsedPrice : (unit.toLowerCase() == "minggu" ? parsedPrice / 168 : parsedPrice / 24);
                                
                                itemModel = ItemModel(
                                  id: itemId,
                                  ownerId: FirebaseAuth.instance.currentUser?.uid ?? '',
                                  ownerName: item['owner']?.toString() ?? 'Owner',
                                  ownerRating: 4.8,
                                  categoryId: '',
                                  categoryName: '',
                                  name: item['name'],
                                  description: '',
                                  pricePerHour: computedPricePerHour,
                                  price: parsedPrice,
                                  priceUnit: unit,
                                  status: status,
                                  condition: 'fair',
                                  photos: [item['image']],
                                );
                              } catch (_) {}
                              
                              if (itemModel == null) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddProductScreen(
                                    editItem: itemModel,
                                  ),
                                ),
                              ).then((_) => _loadItems());
                            },
                            onDeletePressed: () async {
                              final itemId = item['id']?.toString() ?? '';
                              if (itemId.isEmpty) {
                                showAppErrorSnack(context, 'Barang simulasi tidak dapat dihapus.');
                                return;
                              }
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: const Color(0xFFFFF8EF),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  title: Text(isArchived ? 'Hapus Permanen?' : 'Arsipkan Barang?', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
                                  content: Text(isArchived ? 'Apakah Anda yakin ingin menghapus barang ini secara permanen dari riwayat Anda?' : 'Apakah Anda yakin ingin mengarsipkan barang ini?', style: const TextStyle(fontFamily: 'Poppins')),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Batal', style: TextStyle(color: Color(0xFF585D59))),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFE33629),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onPressed: () => Navigator.pop(context, true),
                                      child: Text(isArchived ? 'Hapus' : 'Arsipkan', style: const TextStyle(color: Colors.white)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true || !mounted) return;

                              try {
                                final token = await const AuthSessionService().getValidIdToken();
                                final response = await http.delete(
                                  Uri.parse('${ApiConfig.baseUrl}/items/$itemId'),
                                  headers: {
                                    'Authorization': 'Bearer $token',
                                  },
                                );
                                if (response.statusCode == 200) {
                                  if (!mounted) return;
                                  showAppSuccessSnack(context, isArchived ? 'Barang berhasil dihapus!' : 'Barang berhasil diarsipkan!');
                                  _loadItems();
                                } else {
                                  if (!mounted) return;
                                  showAppErrorSnack(context, 'Gagal memproses barang.');
                                }
                              } catch (e) {
                                if (!mounted) return;
                                showAppErrorSnack(context, 'Terjadi kesalahan: $e');
                              }
                            },
                          );
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
