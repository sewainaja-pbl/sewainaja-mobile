import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'data/models/item_model.dart';
import 'data/repositories/item_repository.dart';
import 'favorite_service.dart';
import 'item_detail_screen.dart';
import 'image_upload_service.dart';
import 'main_navigation_screen.dart';
import 'widgets/custom_app_bar.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final ItemRepository _itemRepo = ItemRepository();
  List<ItemModel> _favoriteItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final favIds = await FavoriteService.getFavorites();
      if (favIds.isEmpty) {
        if (mounted) {
          setState(() {
            _favoriteItems = [];
            _isLoading = false;
          });
        }
        return;
      }

      // Ambil all searchable items (items dengan status available)
      final allItems = await _itemRepo.watchSearchableItems().first;
      final filtered = allItems.where((item) => favIds.contains(item.id)).toList();
      
      if (mounted) {
        setState(() {
          _favoriteItems = filtered;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  ImageProvider _buildImageProvider(String imagePath) {
    final safeUrl = getSafeImageUrl(imagePath);
    if (safeUrl.startsWith('http://') || safeUrl.startsWith('https://')) {
      return ResizeImage(CachedNetworkImageProvider(safeUrl), width: 160);
    }
    return AssetImage(safeUrl);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border_rounded,
            size: 64,
            color: const Color(0xFF012D1D).withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum ada barang favorit',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF414844),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Barang yang kamu sukai akan muncul di sini',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 13,
              color: const Color(0xFF414844).withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Krem Terang
      appBar: const CustomAppBar(
        title: 'Favorite Saya',
      ),
      extendBody: true,
      body: Stack(
        children: [
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF012D1D),
                  ),
                )
              : _favoriteItems.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 120.0),
                  itemCount: _favoriteItems.length,
                  itemBuilder: (context, index) {
                    final item = _favoriteItems[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ItemDetailScreen(
                                itemId: item.id,
                                item: item,
                                itemName: item.name,
                                pricePerHour: item.pricePerHour,
                                imagePath: item.primaryPhoto,
                              ),
                            ),
                          ).then((_) => _loadFavorites());
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFFFF),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Image Thumbnail
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F5F5),
                                  borderRadius: BorderRadius.circular(15),
                                  image: item.primaryPhoto.isNotEmpty
                                      ? DecorationImage(
                                          image: _buildImageProvider(item.primaryPhoto),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: item.primaryPhoto.isEmpty
                                    ? const Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Color(0xFFB0B0B0),
                                        size: 24,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              
                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600, // Semibold
                                        color: Color(0xFF414844),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "Pemilik: ${item.ownerName}",
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400, // Regular
                                        color: Color(0xFF414844),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.formattedPrice,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF012D1D),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Favorite Icon
                              GestureDetector(
                                onTap: () async {
                                  await FavoriteService.toggleFavorite(item.id);
                                  _loadFavorites();
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${item.name} dihapus dari Favorit!',
                                        style: const TextStyle(fontFamily: 'Poppins'),
                                      ),
                                      backgroundColor: const Color(0xFF012D1D),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                behavior: HitTestBehavior.opaque,
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.favorite_rounded,
                                    color: Color(0xFFE33629), // Red
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double horizontalMargin = screenWidth < 360 ? 12.0 : 20.0;
    final double horizontalPadding = screenWidth < 360 ? 8.0 : 10.0;
    final double itemSize = screenWidth < 360 ? 46.0 : 55.0;
    final double iconSize = screenWidth < 360 ? 20.0 : 24.0;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          height: 75,
          margin: EdgeInsets.only(left: horizontalMargin, right: horizontalMargin, bottom: 20),
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
              _buildNavItem(index: 0, activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined, itemSize: itemSize, iconSize: iconSize),
              _buildNavItem(index: 1, activeIcon: Icons.grid_view_rounded, inactiveIcon: Icons.grid_view_outlined, itemSize: itemSize, iconSize: iconSize),
              _buildNavItem(index: 2, activeIcon: Icons.add_box_rounded, inactiveIcon: Icons.add_box_outlined, itemSize: itemSize, iconSize: iconSize),
              _buildNavItem(index: 3, activeIcon: Icons.chat_bubble_rounded, inactiveIcon: Icons.chat_bubble_outline_rounded, itemSize: itemSize, iconSize: iconSize),
              _buildNavItem(index: 4, activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded, itemSize: itemSize, iconSize: iconSize),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required double itemSize,
    required double iconSize,
  }) {
    final bool isActive = 4 == index; // Profile is always active in FavoritesScreen

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
        width: itemSize,
        height: itemSize,
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
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
