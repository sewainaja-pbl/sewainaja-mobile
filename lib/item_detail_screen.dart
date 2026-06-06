import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:animate_do/animate_do.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'add_product_screen.dart';
import 'ajukan_sewa_screen.dart';
import 'api_config.dart';
import 'app_feedback.dart';
import 'auth_session_service.dart';
import 'data/models/item_model.dart';
import 'data/repositories/item_repository.dart';
import 'image_upload_service.dart';
import 'map_common_widgets.dart';
import 'map_explore_screen.dart';
import 'profile_view_screen.dart';
import 'favorite_service.dart';
import 'help_center_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/report_dialog.dart';
import 'room_chat_screen.dart';


class ItemDetailScreen extends StatefulWidget {
  final ItemModel? item;
  final String? itemId;
  final String? itemName;
  final double? pricePerHour;
  final String? sellerLocation;
  final String? imagePath;
  final bool isLocalAsset;

  const ItemDetailScreen({
    super.key,
    this.item,
    this.itemId,
    this.itemName,
    this.pricePerHour,
    this.sellerLocation,
    this.imagePath,
    this.isLocalAsset = false,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  final ItemRepository _itemRepository = ItemRepository();
  bool isDescriptionExpanded = false;
  bool _isLoading = false;
  Map<String, dynamic>? _itemData;
  LatLng _itemCenter = const LatLng(-6.9791, 110.4208);
  bool _isFavorite = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.item != null) {
      _itemData = widget.item!.toJson();
      _updateCenterFromData();
    }
    _fetchItemDetails();
    _initFavoriteState();
  }

  void _initFavoriteState() async {
    final itemId = widget.itemId ?? widget.item?.id;
    if (itemId != null && itemId.isNotEmpty) {
      final isFav = await FavoriteService.isFavorite(itemId);
      if (mounted) {
        setState(() => _isFavorite = isFav);
      }
    }
  }

  void _updateCenterFromData() {
    if (_itemData == null) return;
    final address = _itemData!['address'] as Map<String, dynamic>?;
    final coordinat = address?['coordinat'] as Map<String, dynamic>?;
    if (coordinat != null) {
      final lat = (coordinat['latitude'] as num?)?.toDouble();
      final lng = (coordinat['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _itemCenter = LatLng(lat, lng);
      }
    }
  }

  Future<void> _fetchItemDetails() async {
    final itemId = widget.itemId ?? widget.item?.id;
    if (itemId == null || itemId.isEmpty) return;

    if (mounted) {
      setState(() => _isLoading = _itemData == null);
    }
    try {
      final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/items/$itemId'));
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true && body['data'] != null) {
          if (mounted) {
            setState(() {
              _itemData = body['data'] as Map<String, dynamic>;
              _updateCenterFromData();
            });
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Color _getConditionColor(String? condition) {
    if (condition == null) return const Color(0xFF00796B);
    final lowerCond = condition.toLowerCase();
    if (lowerCond == 'new' || lowerCond.contains('excellent')) {
      return const Color(0xFF1B4332); // deep green
    } else if (lowerCond.contains('like-new') || lowerCond.contains('like_new') || lowerCond.contains('sangat baik')) {
      return const Color(0xFF00796B); // teal
    } else if (lowerCond.contains('good') || lowerCond.contains('baik') || lowerCond.contains('fair') || lowerCond.contains('cukup')) {
      return const Color(0xFF7B5804); // gold/accent brown
    } else if (lowerCond.contains('poor') || lowerCond.contains('buruk')) {
      return const Color(0xFFE33629); // danger red
    }
    return const Color(0xFF00796B);
  }

  String _formatCondition(String? condition) {
    if (condition == null || condition.trim().isEmpty) return 'Sangat Baik';
    final lowerCond = condition.toLowerCase();
    if (lowerCond == 'new') {
      return 'Baru';
    } else if (lowerCond.contains('like-new') || lowerCond.contains('like_new') || lowerCond.contains('sangat baik')) {
      return 'Sangat Baik';
    } else if (lowerCond.contains('good') || lowerCond.contains('baik')) {
      return 'Baik';
    } else if (lowerCond.contains('fair') || lowerCond.contains('cukup')) {
      return 'Cukup';
    } else if (lowerCond.contains('poor') || lowerCond.contains('buruk')) {
      return 'Kurang Baik';
    }
    return condition[0].toUpperCase() + condition.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    const double heroImageHeightFactor = 0.40;

    final List<String> photos = [];
    if (_itemData?['photos'] != null) {
      final rawPhotos = _itemData!['photos'] as List;
      for (final p in rawPhotos) {
        if (p != null && p.toString().isNotEmpty) {
          photos.add(p.toString());
        }
      }
    }
    if (photos.isEmpty && widget.item?.photos != null) {
      for (final p in widget.item!.photos) {
        if (p.isNotEmpty) {
          photos.add(p);
        }
      }
    }
    if (photos.isEmpty && widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      photos.add(widget.imagePath!);
    }
    if (photos.isEmpty) {
      photos.add('assets/images/Iklan.jpg');
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Base canvas color
      body: Stack(
        children: [
          // -------------------------------------------------------------------
          // Layer 1 (Dasar): IMAGE BACKGROUND & TOP ACTIONS
          // -------------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * heroImageHeightFactor, // Hero image height
            child: Stack(
              children: [
                PageView.builder(
                  itemCount: photos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final photoPath = photos[index];
                    final isLocal = widget.isLocalAsset || (!photoPath.startsWith('http') && !photoPath.startsWith('assets/'));
                    
                    if (isLocal && !photoPath.startsWith('assets/')) {
                      return Image.file(
                        File(photoPath),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      );
                    } else if (photoPath.startsWith('http://') || photoPath.startsWith('https://')) {
                      return CachedNetworkImage(
                        imageUrl: photoPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF012D1D),
                          ),
                        ),
                        errorWidget: (context, url, error) => Image.asset(
                          'assets/images/Iklan.jpg',
                          fit: BoxFit.cover,
                          alignment: Alignment.center,
                        ),
                      );
                    } else {
                      return Image.asset(
                        photoPath.isEmpty ? 'assets/images/Iklan.jpg' : photoPath,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      );
                    }
                  },
                ),
                // Indicator dots
                if (photos.length > 1)
                  Positioned(
                    bottom: 45, // Slightly above the bottom sheet overlap
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        photos.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _currentImageIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index
                                ? const Color(0xFF012D1D)
                                : Colors.white.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // -------------------------------------------------------------------
          // Layer 2 (Tengah): SCROLLABLE PRODUCT INFO SHEET
          // -------------------------------------------------------------------
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Spacer Transparan agar sheet tidak menutupi gambar secara default di atas
                  SizedBox(height: (screenHeight * heroImageHeightFactor) - 30),

                  // ### [SECTION 2: SCROLLABLE PRODUCT INFO SHEET]
                  FadeInUp(
                    duration: const Duration(milliseconds: 600),
                    child: Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDF9F4), // ID: '259:1971'
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 15,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 32.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- 2A. MAIN INFO ---
                          _buildTitleAndBadges(),
                          const SizedBox(height: 24),

                          // Divider
                          const Divider(
                            height: 1,
                            color: Color(0xFFE0E0E0),
                            thickness: 1,
                          ),
                          const SizedBox(height: 24),

                          // --- 2D. DESCRIPTION SECTION (With Toggle logic) ---
                          _buildDescription(),
                          const SizedBox(height: 32),

                          // --- 2B. SELLER PROFILE CARD ---
                          _buildSellerProfileCard(),
                          const SizedBox(height: 32),

                          // --- 2C. LOCATION RADIUS MAP ---
                          _buildLocationRadiusMap(),
                          const SizedBox(height: 32),

                          // --- 2E. RECOMMENDATION SLIDER ---
                          _buildRecommendationSlider(),

                          // Padding bottom sangat penting agar konten tidak tertutup Bottom Action Bar (Layer 3)
                          const SizedBox(height: 130),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Layer Navigasi Mengambang di Atas Gambar
          // -------------------------------------------------------------------
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Left Action: Back Button
                    _buildCircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    // Top Right Actions
                    Row(
                      children: [
                        _buildCircleButton(
                          icon: Icons.share_rounded,
                          onTap: _showShareSheet,
                        ),
                        const SizedBox(width: 12),
                        _buildCircleButton(
                          icon: Icons.more_vert_rounded,
                          onTap: _showMoreOptionsSheet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // -------------------------------------------------------------------
          // Layer 3 (Atas): BOTTOM ACTION BAR (Melayang Fixed)
          // -------------------------------------------------------------------
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: const Color(0xFFFDF9F4),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF012D1D)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper: Floating Circle Button
  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Color(0xFF012D1D), // Circle Background: #012D1D
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFFFDF9F4), // Icon Color: #FDF9F4
        ),
      ),
    );
  }

  // 2A. MAIN INFO
  Widget _buildTitleAndBadges() {
    final itemName = _itemData?['name']?.toString() ?? widget.itemName ?? "";
    final priceRaw = _itemData?['pricePerHour'] ?? widget.pricePerHour ?? 15000.0;
    final priceVal = (priceRaw as num).toDouble();
    final itemPrice = "Rp. ${priceVal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}/jam";
    
    final cond = _itemData?['condition']?.toString();
    final hasCondition = cond != null && cond.trim().isNotEmpty;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName, // ID: '259:1979'
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    itemPrice, // ID: '259:1980'
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Color(0xFF7B5804), // Color_Accent_Brown
                    ),
                  ),
                ],
              ),
            ),
            // Action: Heart/Like Icon
            GestureDetector(
              onTap: () async {
                final itemId = widget.itemId ?? widget.item?.id;
                if (itemId != null && itemId.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final nowFav = await FavoriteService.toggleFavorite(itemId);
                  if (!mounted) return;
                  setState(() => _isFavorite = nowFav);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        nowFav ? '${widget.itemName ?? _itemData?['name'] ?? 'Barang'} disimpan ke Favorit!' : '${widget.itemName ?? _itemData?['name'] ?? 'Barang'} dihapus dari Favorit!',
                        style: const TextStyle(fontFamily: 'Poppins'),
                      ),
                      backgroundColor: const Color(0xFF012D1D),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                child: Icon(
                  _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  size: 28,
                  color: const Color(0xFFE33629), // Color_Danger_Red
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Badge Condition
            if (hasCondition)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: _getConditionColor(cond),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Text(
                  _formatCondition(cond),
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            if (hasCondition) const SizedBox(width: 16),
            // Clock Info
            const Icon(
              Icons.access_time_rounded,
              size: 18,
              color: Colors.black54,
            ),
            const SizedBox(width: 6),
            Text(
              _formatTimeAgo(_itemData?['createdAt'] ?? widget.item?.createdAt),
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  DateTime? _parseTimestamp(dynamic val) {
    if (val == null) return null;
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val)?.toLocal();
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    if (val is Timestamp) return val.toDate().toLocal();
    if (val is Map) {
      final rawSeconds = val['_seconds'] ?? val['seconds'];
      if (rawSeconds is int) {
        final rawNanos = val['_nanoseconds'] ?? val['nanoseconds'];
        final nanos = rawNanos is int ? rawNanos : 0;
        return DateTime.fromMillisecondsSinceEpoch(
          (rawSeconds * 1000) + (nanos ~/ 1000000),
          isUtc: true,
        ).toLocal();
      }
    }
    return null;
  }

  DateTime? _extractTimestampFromUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    try {
      final decodedUrl = Uri.decodeComponent(url);
      final regex = RegExp(r'(\d{10,13})_\d+\.(?:jpg|jpeg|png|webp|gif)', caseSensitive: false);
      final match = regex.firstMatch(decodedUrl);
      if (match != null) {
        final tsStr = match.group(1);
        if (tsStr != null) {
          final ts = int.tryParse(tsStr);
          if (ts != null) {
            if (tsStr.length == 13) {
              return DateTime.fromMillisecondsSinceEpoch(ts).toLocal();
            } else if (tsStr.length == 10) {
              return DateTime.fromMillisecondsSinceEpoch(ts * 1000).toLocal();
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeAgo(dynamic createdAt) {
    DateTime? dateTime = _parseTimestamp(createdAt);
    
    if (dateTime == null) {
      final photos = _itemData?['photos'] as List?;
      if (photos != null && photos.isNotEmpty) {
        for (final photo in photos) {
          final extracted = _extractTimestampFromUrl(photo?.toString());
          if (extracted != null) {
            dateTime = extracted;
            break;
          }
        }
      }
    }
    
    if (dateTime == null) {
      final photos = widget.item?.photos;
      if (photos != null && photos.isNotEmpty) {
        for (final photo in photos) {
          final extracted = _extractTimestampFromUrl(photo);
          if (extracted != null) {
            dateTime = extracted;
            break;
          }
        }
      }
    }
    
    if (dateTime == null) {
      dateTime = _extractTimestampFromUrl(widget.imagePath);
    }
    
    if (dateTime == null) return "Baru saja";
    
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) {
      return "Baru saja";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes} menit yang lalu";
    } else if (diff.inHours < 24) {
      return "${diff.inHours} jam yang lalu";
    } else if (diff.inDays < 30) {
      return "${diff.inDays} hari yang lalu";
    } else {
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    }
  }

  String _getDynamicDescription(String? itemName) {
    if (itemName == null || itemName.trim().isEmpty) return "Barang sewaan berkualitas dengan kondisi yang masih sangat baik. Sangat cocok digunakan untuk berbagai keperluan Anda.";
    
    final lowerName = itemName.toLowerCase();
    if (lowerName.contains("sony a6000")) {
      return "Sony a6000 adalah kamera mirrorless APS-C 24,3 MP yang andal, populer untuk pemula dan traveling karena ukurannya ringkas, autofokus cepat (11 fps), dan harga terjangkau. Kondisi barang sangat terawat, lensa bersih tanpa jamur sama sekali. Cocok untuk pemula hingga profesional untuk event fotografi maupun videografi ringan. Termasuk tas kamera, 1 baterai ekstra, dan charger bawaan.";
    } else if (lowerName.contains("airpods")) {
      return "Apple AirPods Max 2 memberikan pengalaman mendengarkan audio yang tak tertandingi dengan Active Noise Cancellation terdepan di industri. Bantalan telinga sangat nyaman dipakai berjam-jam. Kondisi mulus 99%, baterai awet, lengkap dengan Smart Case bawaan.";
    } else if (lowerName.contains("ps5") || lowerName.contains("dual-sense") || lowerName.contains("controller")) {
      return "Controller Sony DualSense PS5 original, kondisi fisik mulus dan fungsi tombol serta analog 100% normal tanpa drift. Haptic feedback dan adaptive triggers berfungsi sempurna. Cocok untuk mabar bersama teman atau sekadar bermain solo.";
    } else if (lowerName.contains("sony w830") || lowerName.contains("cybershot")) {
      return "Kamera digital saku Sony W830 20.1 MP. Kamera yang sangat praktis dibawa kemana saja, hasil foto tajam khas Sony dengan 8x optical zoom. Cocok untuk mengabadikan momen casual dan street photography. Termasuk memory card 32GB dan pouch.";
    } else if (lowerName.contains("tenda")) {
      return "Tenda camping kapasitas 4 orang dengan bahan double layer tahan air (waterproof). Frame kokoh dan mudah dirakit, sangat cocok untuk kegiatan outdoor atau hiking bersama teman dan keluarga.";
    } else if (lowerName.contains("bor") || lowerName.contains("drill")) {
      return "Mesin bor listrik bertenaga dengan berbagai kecepatan. Lengkap dengan set mata bor untuk kayu, besi, dan beton. Kondisi terawat dan siap digunakan untuk kebutuhan pertukangan Anda.";
    } else {
      return "$itemName merupakan barang sewaan berkualitas yang kami tawarkan dengan kondisi fisik dan fungsi terbaik. Barang selalu dirawat secara rutin sehingga dapat berfungsi dengan optimal untuk menunjang aktivitas Anda. Jangan ragu untuk menyewa atau menghubungi *owner* jika ada pertanyaan lebih lanjut mengenai spesifikasi detail barang ini.";
    }
  }

  // 2D. DESCRIPTION SECTION (DENGAN EXPAND TOGGLE)
  Widget _buildDescription() {
    final String descFromApi = _itemData?['description'] as String? ?? '';
    final String descFromWidget = widget.item?.description ?? '';
    final String fallbackDesc = _getDynamicDescription(widget.itemName ?? _itemData?['name']);
    final String fullDescription = descFromApi.isNotEmpty
        ? descFromApi
        : (descFromWidget.isNotEmpty ? descFromWidget : fallbackDesc);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Description", // ID: '270:1322'
              style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600, // SemiBold
                fontSize: 20,
                color: Colors.black,
              ),
            ),
            // Toggle Show More / Less
            GestureDetector(
              onTap: () {
                setState(() {
                  isDescriptionExpanded = !isDescriptionExpanded;
                });
              },
              child: Row(
                children: [
                  Text(
                    isDescriptionExpanded
                        ? "See less"
                        : "See more", // ID: '270:1324'
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  Icon(
                    isDescriptionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: const Color(0xFF012D1D),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          alignment: Alignment.topCenter,
          child: Text(
            fullDescription, // ID: '270:1327'
            maxLines: isDescriptionExpanded ? null : 2,
            overflow: isDescriptionExpanded ? null : TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Inter', // Dinyatakan khusus dalam spesifikasi
              fontWeight: FontWeight.w300, // Light / 300
              fontSize: 12,
              height: 1.6,
              color: Color(0xFF414844),
            ),
          ),
        ),
      ],
    );
  }

  // 2B. SELLER PROFILE CARD
  Widget _buildSellerProfileCard() {
    final String sellerName = _itemData?['ownerName'] as String? ?? widget.item?.ownerName ?? 'Han Soo Hee';
    final double ratingRaw = ((_itemData?['ownerRating'] ?? widget.item?.ownerRating ?? 4.9) as num).toDouble();
    final String ratingStr = ratingRaw > 0 ? ratingRaw.toStringAsFixed(1) : "—";
    final String? addressLabel = _itemData?['address']?['label']?.toString() ?? _itemData?['address']?['fullAddress']?.toString();
    final String sellerLoc = addressLabel ?? widget.sellerLocation ?? "Tembalang, Banyumanik";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileViewScreen(
              ownerId: _itemData?['ownerId'] as String? ?? widget.item?.ownerId,
              ownerName: sellerName,
              avatarImage: const AssetImage('assets/images/profile_user.png'),
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, // ID: '259:1991'
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black, // Border: 1px Solid #000000
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar Image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/profile_user.png'),
                  fit: BoxFit.cover,
                ),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
              ),
            ),
            const SizedBox(width: 12),
            // Seller Name & Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sellerName,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500, // Regular to Medium
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFF8BD00),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ratingStr,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "| $sellerLoc",
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Chat Action Button
            GestureDetector(
              onTap: () {
                final String partnerId = _itemData?['ownerId']?.toString() ?? widget.item?.ownerId ?? "";
                final String partnerName = _itemData?['ownerName']?.toString() ?? "User";
                final String partnerAvatarUrl = ""; // Fetch from users collection or leave empty
                final String itemId = widget.itemId ?? widget.item?.id ?? "";
                final String itemName = _itemData?['name']?.toString() ?? widget.itemName ?? "";
                final String itemPhotoUrl = (_itemData?['photos'] as List?)?.isNotEmpty == true 
                    ? _itemData!['photos'][0].toString() 
                    : (widget.imagePath ?? "");

                if (partnerId.isNotEmpty && itemId.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomChatScreen(
                        partnerId: partnerId,
                        partnerName: partnerName,
                        partnerAvatarUrl: partnerAvatarUrl,
                        itemId: itemId,
                        itemName: itemName,
                        itemPhotoUrl: itemPhotoUrl,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF012D1D).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.solidCommentDots,
                  size: 16,
                  color: Color(0xFF012D1D),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2C. LOCATION RADIUS MAP
  Widget _buildLocationRadiusMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Radius Lokasi Barang", // ID: '259:1972'
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 20,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapExploreScreen()),
            );
          },
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25), // ID: '259:1977'
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ReusableMapCard(
              center: _itemCenter,
              zoom: 13.0,
              radiusKm: 1.5,
              interactive: false,
              markers: [MapMarkerData(point: _itemCenter, highlighted: true)],
              overlayLabel: 'Estimasi jangkauan 1.5 km dari titik barang (Tap untuk detail)',
              borderRadius: BorderRadius.circular(25),
              height: 180,
            ),
          ),
        ),
      ],
    );
  }

  // 2E. RECOMMENDATION SLIDER (Horizontal Scroll)
  Widget _buildRecommendationSlider() {
    final String? activeCategory = _itemData?['categoryName']?.toString() ?? widget.item?.categoryName;
    final String? currentItemId = widget.itemId ?? widget.item?.id;

    final Stream<List<ItemModel>> primaryStream = (activeCategory != null && activeCategory.isNotEmpty)
        ? _itemRepository.watchAvailableItems(categoryName: activeCategory)
        : _itemRepository.watchAvailableItems(categoryName: 'All');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recommendation", // ID: '277:2085'
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600, // SemiBold
            fontSize: 20,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 190, // Tinggi list slider
          child: StreamBuilder<List<ItemModel>>(
            stream: primaryStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF012D1D)),
                  ),
                );
              }

              List<ItemModel> recommended = [];
              if (snapshot.hasData) {
                recommended = snapshot.data!
                    .where((item) => item.id != currentItemId)
                    .toList();
              }

              if (recommended.isEmpty) {
                // Fallback to all available items
                return StreamBuilder<List<ItemModel>>(
                  stream: _itemRepository.watchAvailableItems(categoryName: 'All'),
                  builder: (context, fallbackSnapshot) {
                    if (fallbackSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF012D1D)),
                        ),
                      );
                    }

                    List<ItemModel> fallbackRecommended = [];
                    if (fallbackSnapshot.hasData) {
                      fallbackRecommended = fallbackSnapshot.data!
                          .where((item) => item.id != currentItemId)
                          .toList();
                    }

                    if (fallbackRecommended.isEmpty) {
                      return const Center(
                        child: Text(
                          "Tidak ada rekomendasi lainnya",
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      );
                    }

                    return _buildRecommendationList(fallbackRecommended.take(10).toList());
                  },
                );
              }

              return _buildRecommendationList(recommended.take(10).toList());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationList(List<ItemModel> items) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 16),
      itemBuilder: (context, index) {
        return _RecommendationCardItem(item: items[index]);
      },
    );
  }

  Map<String, dynamic> _buildFallbackItemData() {
    return {
      'id': widget.itemId ?? widget.item?.id ?? '',
      'name': widget.itemName ?? widget.item?.name ?? '',
      'pricePerHour': widget.pricePerHour ?? widget.item?.pricePerHour ?? 15000.0,
      'categoryName': widget.item?.categoryName ?? 'Camera',
      'photos': widget.item?.photos ?? (_itemData?['photos'] ?? []),
      'ownerName': widget.item?.ownerName ?? '',
      'ownerRating': widget.item?.ownerRating ?? 4.9,
    };
  }

  // SECTION 3: FIXED BOTTOM ACTION BAR (Positioned on Stack bottom)
  Widget _buildBottomActionBar() {
    final ownerId = _itemData?['ownerId']?.toString() ?? widget.item?.ownerId;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnItem = currentUserId != null && ownerId == currentUserId;

    return Container(
      // Gradasi halus agar menyatu dengan latar (Optional tapi ditambahkan untuk premium feel)
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFDF9F4).withValues(alpha: 0.0),
            const Color(0xFFFDF9F4).withValues(alpha: 0.9),
            const Color(0xFFFDF9F4),
          ],
          stops: const [0.0, 0.2, 1.0],
        ),
      ),
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 20),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Secondary Action: Chat Button Icon (only if it's not own item)
            if (!isOwnItem) ...[
              GestureDetector(
                onTap: () {
                  final String partnerId = _itemData?['ownerId']?.toString() ?? widget.item?.ownerId ?? "";
                  final String partnerName = _itemData?['ownerName']?.toString() ?? widget.item?.ownerName ?? "User";
                  final String partnerAvatarUrl = ""; // Fetch from users collection or leave empty
                  final String itemId = widget.itemId ?? widget.item?.id ?? "";
                  final String itemName = _itemData?['name']?.toString() ?? widget.itemName ?? "";
                  final List<dynamic>? apiPhotos = _itemData?['photos'] as List<dynamic>?;
                  final String itemPhotoUrl = (apiPhotos != null && apiPhotos.isNotEmpty)
                      ? apiPhotos.first.toString()
                      : (widget.item?.photos.isNotEmpty == true
                          ? widget.item!.photos.first
                          : (widget.imagePath ?? ""));

                  if (partnerId.isNotEmpty && itemId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RoomChatScreen(
                          partnerId: partnerId,
                          partnerName: partnerName,
                          partnerAvatarUrl: partnerAvatarUrl,
                          itemId: itemId,
                          itemName: itemName,
                          itemPhotoUrl: itemPhotoUrl,
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 56,
                  width: 56,
                  decoration: BoxDecoration(
                    color: Colors.white, // Frame putih melingkar
                    border: Border.all(color: const Color(0xFF012D1D), width: 1.5),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: FaIcon(
                      FontAwesomeIcons.solidComments, // ID: '259:2031'
                      color: Color(0xFF012D1D),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
            ],
            // Primary Action: Sewa Sekarang or Edit Barang Button
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (isOwnItem) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(
                          editItem: _getEditItemModel(),
                        ),
                      ),
                    ).then((value) {
                      if (value == true) {
                        _fetchItemDetails();
                      }
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AjukanSewaScreen(
                          itemData: _itemData ?? _buildFallbackItemData(),
                        ),
                      ),
                    );
                  }
                },
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF012D1D), // ID: '259:2029'
                    borderRadius: BorderRadius.circular(277), // Pill shape
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      isOwnItem ? "Edit Barang" : "Sewa Sekarang",
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700, // Bold
                        fontSize: 16,
                        color: Color(0xFFFDF9F4), // Text Color
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ItemModel _getEditItemModel() {
    if (widget.item != null) return widget.item!;
    final data = _itemData ?? _buildFallbackItemData();
    return ItemModel(
      id: data['id']?.toString() ?? '',
      ownerId: data['ownerId']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? '',
      ownerRating: (data['ownerRating'] as num?)?.toDouble() ?? 0.0,
      categoryId: data['categoryId']?.toString() ?? '',
      categoryName: data['categoryName']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      pricePerHour: (data['pricePerHour'] as num?)?.toDouble() ?? 0.0,
      status: data['status']?.toString() ?? 'available',
      condition: data['condition']?.toString() ?? 'fair',
      photos: List<String>.from(data['photos'] as List? ?? []),
    );
  }


  Future<void> _deleteItem() async {
    final itemId = widget.itemId ?? widget.item?.id;
    if (itemId == null) return;
    
    // Confirm dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFFF8EF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Barang?', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: Color(0xFF012D1D))),
        content: const Text('Apakah Anda yakin ingin menghapus barang ini? Status barang akan diarsipkan.', style: TextStyle(fontFamily: 'Poppins')),
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
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isLoading = true);
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
        showAppSuccessSnack(context, 'Barang berhasil dihapus!');
        Navigator.pop(context, true); // Pop back to catalog with success indicator
      } else {
        if (!mounted) return;
        showAppErrorSnack(context, 'Gagal menghapus barang.');
      }
    } catch (_) {
      if (!mounted) return;
      showAppErrorSnack(context, 'Terjadi kesalahan koneksi.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showShareSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bagikan Barang',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildShareOption(
                      icon: const FaIcon(
                        FontAwesomeIcons.whatsapp,
                        color: Color(0xFF25D366),
                        size: 24,
                      ),
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () {
                        Navigator.pop(context);
                        showAppSuccessSnack(context, 'Membuka WhatsApp...');
                      },
                    ),
                    _buildShareOption(
                      icon: const Icon(
                        Icons.copy_all_rounded,
                        color: Color(0xFF012D1D),
                        size: 24,
                      ),
                      label: 'Salin Link',
                      color: const Color(0xFF012D1D),
                      onTap: () {
                        Navigator.pop(context);
                        final itemId = widget.item?.id ?? widget.itemId ?? '';
                        Clipboard.setData(ClipboardData(text: 'https://sewainaja-b4834.web.app/items/$itemId'));
                        showAppSuccessSnack(context, 'Link berhasil disalin ke clipboard!');
                      },
                    ),
                    _buildShareOption(
                      icon: const Icon(
                        Icons.more_horiz_rounded,
                        color: Color(0xFF7B5804),
                        size: 24,
                      ),
                      label: 'Lainnya',
                      color: const Color(0xFF7B5804),
                      onTap: () {
                        Navigator.pop(context);
                        showAppSuccessSnack(context, 'Membuka opsi berbagi...');
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required Widget icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: icon,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF012D1D),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptionsSheet() {
    final ownerId = _itemData?['ownerId']?.toString() ?? widget.item?.ownerId;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwnItem = currentUserId != null && ownerId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              if (isOwnItem) ...[
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Color(0xFF012D1D)),
                  title: const Text('Edit Barang', style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddProductScreen(
                          editItem: _getEditItemModel(),
                        ),
                      ),
                    ).then((value) {
                      if (value == true) {
                        _fetchItemDetails();
                      }
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE33629)),
                  title: const Text('Hapus Barang', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE33629))),
                  onTap: () {
                    Navigator.pop(context);
                    _deleteItem();
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined, color: Color(0xFFE33629)),
                  title: const Text('Laporkan Barang', style: TextStyle(fontFamily: 'Poppins', color: Color(0xFFE33629))),
                  onTap: () {
                    Navigator.pop(context);
                    _showReportDialog();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF012D1D)),
                  title: const Text('Bantuan SewainAja', style: TextStyle(fontFamily: 'Poppins')),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpCenterScreen(),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showReportDialog() {
    final reportedId = widget.item?.ownerId ?? _itemData?['ownerId'] as String? ?? '';
    final itemId = widget.item?.id ?? widget.itemId ?? '';
    final itemName = widget.item?.name ?? _itemData?['name'] as String? ?? widget.itemName ?? 'Barang';

    if (reportedId.isEmpty) {
      showAppErrorSnack(context, 'Data pemilik belum dimuat.');
      return;
    }

    showReportDialog(
      context,
      reportedId: reportedId,
      itemId: itemId,
      itemName: itemName,
    );
  }
}

// ITEM COMPONENT UNTUK RECOMMENDATION SLIDER
class _RecommendationCardItem extends StatelessWidget {
  final ItemModel item;

  const _RecommendationCardItem({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final ImageUploadService imageUploadService = ImageUploadService();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemDetailScreen(
              item: item,
            ),
          ),
        );
      },
      child: Container(
        width: 145,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFF012D1D).withValues(alpha: 0.1),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar produk rekomen
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  image: DecorationImage(
                    image: item.primaryPhoto.isNotEmpty
                        ? imageUploadService.buildImageProvider(item.primaryPhoto, targetWidth: 290)
                        : const AssetImage('assets/images/Iklan.jpg') as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // Text Detail
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: Color(0xFF414844),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.formattedPricePerHour,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
