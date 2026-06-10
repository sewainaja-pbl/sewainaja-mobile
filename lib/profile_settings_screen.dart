import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'api_config.dart';
import 'auth_session_service.dart';
import 'edit_profile_screen.dart';
import 'image_upload_service.dart';
import 'profile_sync_service.dart';
import 'settings_screen.dart';
import 'my_items_screen.dart';
import 'favorites_screen.dart';
import 'transaction_history_screen.dart';
import 'profile_view_screen.dart';
import 'ktp_upload_screen.dart';
import 'wallet_screen.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/transaction_repository.dart';
import 'transaction_detail_screen.dart';
import 'package:intl/intl.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ProfileSettingsScreen({super.key, this.onBack});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  String _name = '';
  String _defaultLocation = '';
  String _profilePhotoUrl = '';
  String _userStatus = '';
  double _walletBalance = 0.0;
  final ImageUploadService _imageUploadService = ImageUploadService();
  final ProfileSyncService _profileSyncService = const ProfileSyncService();

  int _totalSewaCount = 0;
  int _listingCount = 0;
  double _userRating = 0.0;

  final TransactionRepository _transactionRepository = TransactionRepository();
  List<TransactionModel> _realActiveTransactions = [];
  bool _isLoadingTransactions = false;


  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserStats();
    _loadActiveTransactions();
    ProfileSyncService.profileRevision.addListener(
      _handleProfileRevisionChanged,
    );
  }

  @override
  void dispose() {
    ProfileSyncService.profileRevision.removeListener(
      _handleProfileRevisionChanged,
    );
    super.dispose();
  }

  void _handleProfileRevisionChanged() {
    _loadUserData();
    _loadUserStats();
    _loadActiveTransactions();
  }

  Future<void> _loadActiveTransactions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingTransactions = true;
    });
    try {
      final txs = await _transactionRepository.fetchTransactions();
      final active = txs.where((t) =>
        t.status == 'pending' || t.status == 'approved' || t.status == 'ongoing'
      ).toList();

      if (mounted) {
        setState(() {
          _realActiveTransactions = active;
          _isLoadingTransactions = false;
        });
      }

      // Fetch details for each active transaction asynchronously to get item names and photos
      for (var tx in active) {
        if (tx.details.isEmpty) {
          _transactionRepository.fetchTransactionById(tx.id).then((fullTx) {
            if (mounted) {
              setState(() {
                final idx = _realActiveTransactions.indexWhere((t) => t.id == tx.id);
                if (idx != -1) {
                  _realActiveTransactions[idx] = fullTx;
                }
              });
            }
          }).catchError((_) {});
        }
      }
    } catch (e) {
      debugPrint("Error loading active transactions: $e");
      if (mounted) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      final cached = await _profileSyncService.readCachedProfile();
      if (!mounted) return;
      setState(() {
        _name = cached.displayName;
        _profilePhotoUrl = cached.profilePhotoUrl;
        _userStatus = cached.status;
        _walletBalance = cached.walletBalance;
      });
      final prefs = await SharedPreferences.getInstance();
      final cachedLocation = prefs.getString('user_default_location')?.trim();
      if (cachedLocation != null && cachedLocation.isNotEmpty && mounted) {
        setState(() {
          _defaultLocation = cachedLocation;
        });
      }
      final synced = await _profileSyncService.syncProfileFromApi(notify: false);
      if (synced == null || !mounted) return;
      setState(() {
        _name = synced.displayName;
        _profilePhotoUrl = synced.profilePhotoUrl;
        _userStatus = synced.status;
        _walletBalance = synced.walletBalance;
      });
    } catch (_) {}
  }

  Future<void> _loadUserStats() async {
    if (!mounted) return;


    // 1. Fetch Listings & Rating dari Firestore
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        final itemsSnap = await FirebaseFirestore.instance
            .collection('items')
            .where('ownerId', isEqualTo: currentUserId)
            .get();
        final listings = itemsSnap.docs;

        double totalRating = 0.0;
        int ratedCount = 0;
        for (var doc in listings) {
          final rating = (doc.data()['ownerRating'] as num?)?.toDouble() ?? 0.0;
          if (rating > 0.0) {
            totalRating += rating;
            ratedCount++;
          }
        }

        if (mounted) {
          setState(() {
            _listingCount = listings.length;
            _userRating = ratedCount > 0 ? (totalRating / ratedCount) : 0.0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading Firestore stats: $e");
    }

    // 2. Fetch Total Sewa dari REST API
    try {
      final token = await const AuthSessionService().getValidIdToken();
      if (token != null && token.isNotEmpty) {
        final response = await http
            .get(
              Uri.parse('${ApiConfig.baseUrl}/transactions'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final body = jsonDecode(response.body);
          if (body['success'] == true && body['data'] is List) {
            if (mounted) {
              setState(() {
                _totalSewaCount = (body['data'] as List).length;
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading transactions REST stats: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4),
      // --- APPBAR ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        centerTitle: true,
        leadingWidth: 76,
        leading: (widget.onBack != null || Navigator.canPop(context))
            ? Padding(
                padding: const EdgeInsets.only(left: 24, top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF012D1D),
                      size: 28,
                    ),
                  ),
                ),
              )
            : null,
        title: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Text(
            'Profil',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Color(0xFF012D1D),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ### [SECTION 1: PROFILE CARD] ###
            _buildProfileCard(),

            const SizedBox(height: 24),

            // ### [SECTION 2: SEDANG BERLANGSUNG] ###
            _buildActiveRentalSection(),

            const SizedBox(height: 20),

            // ### [SECTION 3: MENU LIST] ###
            _buildMenuList(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SECTION 1: PROFILE CARD
  // ─────────────────────────────────────────────
  Widget _buildProfileCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileViewScreen(
              ownerName: _name,
              rating: "4.9 (Dummy)",
              listingCount: "20 (Dummy)",
              avatarImage: _resolvedProfileImage(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- Header: Avatar + Info ---
          Row(
            children: [
              // Avatar with verified badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF1B4332).withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: Image(
                        image: _resolvedProfileImage(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Image.asset(
                              'assets/images/profile_user.png',
                              fit: BoxFit.cover,
                            ),
                      ),
                    ),
                  ),
                  // Verified badge
                  if (_userStatus.trim().isNotEmpty)
                    Positioned(
                      bottom: 0,
                      right: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _statusBadgeColor(),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _statusBadgeIcon(),
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Name + Rating
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4332),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFF717973),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _defaultLocation,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF717973),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (_userStatus.trim().isNotEmpty)
                      GestureDetector(
                        onTap: () async {
                          if (_userStatus.trim().toLowerCase() != 'verified') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KtpUploadScreen()),
                            );
                            _loadUserData();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: _statusBackgroundColor(),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _statusLabel(),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _statusTextColor(),
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          ...List.generate(
                            5,
                            (i) => const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFF8BD00),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_userRating > 0.0 ? _userRating.toStringAsFixed(1) : '0.0'} ($_totalSewaCount)',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF000000),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // --- Stats Box ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EDE8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  _buildStatColumn(
                    'TOTAL SEWA',
                    '$_totalSewaCount',
                  ),
                  _buildVerticalDivider(),
                  _buildStatColumn(
                    'LISTING',
                    '$_listingCount',
                  ),
                  _buildVerticalDivider(),
                  _buildStatColumn(
                    'RATING',
                    _userRating > 0.0
                        ? _userRating.toStringAsFixed(1)
                        : '0.0',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildStatColumn(String title, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Color(0xFF414844),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF000000),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(width: 1, color: const Color(0xFFD5BF87));
  }

  // ─────────────────────────────────────────────
  // SECTION 2: SEDANG BERLANGSUNG
  // ─────────────────────────────────────────────

  Widget _buildActiveRentalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sedang Berlangsung',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                  );
                },
                child: const Text(
                  'More',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Dynamic slider/content
        SizedBox(
          height: 100,
          child: _isLoadingTransactions
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF012D1D)),
                )
              : _realActiveTransactions.isEmpty
                  ? Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline_rounded, color: Colors.grey.shade400, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Tidak ada penyewaan berlangsung.',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _realActiveTransactions.length,
                      itemBuilder: (context, index) {
                        final item = _realActiveTransactions[index];
                        final detail = item.details.isNotEmpty ? item.details.first : null;
                        final String itemName = detail?.itemNameSnapshot ?? "Transaksi ${item.id.substring(0, 5)}";
                        final String itemImage = detail?.itemPhotoUrlSnapshot ?? "";
                        
                        String dateRange = "";
                        if (detail != null && detail.startDate != null && detail.endDate != null) {
                          dateRange = "${DateFormat('d MMM').format(detail.startDate!)} - ${DateFormat('d MMM yyyy').format(detail.endDate!)}";
                        }

                        // Determine partner description
                        final currentUid = FirebaseAuth.instance.currentUser?.uid;
                        final partnerLabel = item.renterId == currentUid
                            ? 'Pemilik: ${item.ownerName}'
                            : 'Penyewa: ${item.renterName}';

                        // Map status
                        String displayStatus = 'Pending';
                        Color badgeColor = const Color(0xFFE0E0E0);
                        Color textColor = Colors.black;
                        switch (item.status.toLowerCase()) {
                          case 'pending':
                            displayStatus = 'Pending';
                            badgeColor = const Color(0xFFFFF4DB);
                            textColor = const Color(0xFF9A6700);
                            break;
                          case 'approved':
                            displayStatus = 'Disetujui';
                            badgeColor = const Color(0xFFD0E1D4);
                            textColor = const Color(0xFF012D1D);
                            break;
                          case 'ongoing':
                            displayStatus = 'Aktif';
                            badgeColor = const Color(0xFFF87400);
                            textColor = Colors.white;
                            break;
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TransactionDetailScreen(transactionId: item.id),
                              ),
                            ).then((_) {
                              _loadActiveTransactions();
                              _loadUserStats();
                            });
                          },
                          child: Container(
                            width: 280,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Product image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: itemImage.isNotEmpty && itemImage.startsWith('http')
                                      ? Image.network(
                                          itemImage,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              Container(
                                                width: 64,
                                                height: 64,
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFE0E0E0),
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: const Icon(
                                                  Icons.image_outlined,
                                                  color: Color(0xFF9E9E9E),
                                                ),
                                              ),
                                        )
                                      : Container(
                                          width: 64,
                                          height: 64,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE0E0E0),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Icon(
                                            Icons.image_outlined,
                                            color: Color(0xFF9E9E9E),
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Product details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        itemName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF414844),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        partnerLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF414844),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateRange,
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF414844),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    displayStatus,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SECTION 3: MENU LIST
  // ─────────────────────────────────────────────
  Widget _buildMenuList() {
    final menuItems = [
      _MenuItem(
        title: 'Edit Profil',
        icon: Icons.edit_outlined,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditProfileScreen()),
          );
          _loadUserData();
        },
      ),
      if (_userStatus.trim().toLowerCase() != 'verified')
        _MenuItem(
          title: _userStatus.trim().toLowerCase() == 'pending'
              ? 'Status Verifikasi (Pending)'
              : 'Verifikasi Identitas (KTP)',
          icon: Icons.gpp_maybe_outlined,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const KtpUploadScreen()),
            );
            _loadUserData();
          },
        ),
      _MenuItem(
        title: 'Barang Saya',
        icon: Icons.inventory_2_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MyItemsScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'Favorit Saya',
        icon: Icons.favorite_border_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FavoritesScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'Dompet Saya',
        icon: Icons.account_balance_wallet_outlined,
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WalletScreen(currentBalance: _walletBalance),
            ),
          );
          _loadUserData();
        },
      ),
      _MenuItem(
        title: 'Riwayat',
        icon: Icons.history_rounded,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
          );
        },
      ),
      _MenuItem(
        title: 'Pengaturan',
        icon: Icons.settings_outlined,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen()),
          );
        },
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F3EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(menuItems.length, (index) {
          final item = menuItems[index];
          final isLast = index == menuItems.length - 1;
          return _buildMenuItem(item, isLast: isLast);
        }),
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item, {bool isLast = false}) {
    return GestureDetector(
      onTap: item.onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icon box
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item.icon,
                    color: const Color(0xFF012D1D),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Title
                Expanded(
                  child: Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1C1C19),
                    ),
                  ),
                ),
                // Chevron
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFC1C8C2),
                  size: 22,
                ),
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 1,
              color: const Color(0xFFE8E4DE),
              indent: 68,
              endIndent: 16,
            ),
        ],
      ),
    );
  }

  ImageProvider _resolvedProfileImage() {
    if (_profilePhotoUrl.trim().isNotEmpty) {
      return _imageUploadService.buildImageProvider(_profilePhotoUrl, targetWidth: 128);
    }
    return const AssetImage('assets/images/profile_user.png');
  }

  String _statusLabel() {
    switch (_userStatus.trim().toLowerCase()) {
      case 'verified':
        return 'Terverifikasi';
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'unverified':
        return 'Belum Verifikasi';
      case 'suspended':
        return 'Ditangguhkan';
      default:
        return _userStatus;
    }
  }

  Color _statusBackgroundColor() {
    switch (_userStatus.trim().toLowerCase()) {
      case 'verified':
        return const Color(0xFFE9F7EF);
      case 'pending':
        return const Color(0xFFFFF4DB);
      case 'suspended':
        return const Color(0xFFFDECEC);
      default:
        return const Color(0xFFF1EDE8);
    }
  }

  Color _statusTextColor() {
    switch (_userStatus.trim().toLowerCase()) {
      case 'verified':
        return const Color(0xFF1B7F4C);
      case 'pending':
        return const Color(0xFF9A6700);
      case 'suspended':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFF414844);
    }
  }

  Color _statusBadgeColor() {
    switch (_userStatus.trim().toLowerCase()) {
      case 'verified':
        return const Color(0xFF012D1D);
      case 'pending':
        return const Color(0xFF9A6700);
      case 'suspended':
        return const Color(0xFFB42318);
      default:
        return const Color(0xFF717973);
    }
  }

  IconData _statusBadgeIcon() {
    switch (_userStatus.trim().toLowerCase()) {
      case 'verified':
        return Icons.verified_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'suspended':
        return Icons.block_rounded;
      default:
        return Icons.person_outline_rounded;
    }
  }
}

// Simple data class for menu items
class _MenuItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
