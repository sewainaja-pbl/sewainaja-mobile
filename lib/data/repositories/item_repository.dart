import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../auth_session_service.dart';

/// Repository untuk mengakses collection `items` di Firestore.
/// Mengikuti pola repository sesuai AGENTS.md.
class ItemRepository {
  ItemRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _db.collection('items');
      
  final AuthSessionService _authService = const AuthSessionService();

  // ---------------------------------------------------------------------------
  // FOLLOWING ITEMS
  // ---------------------------------------------------------------------------

  Future<List<ItemModel>> getFollowingItems() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return [];
    }

    try {
      final followsSnapshot = await _db
          .collection('follows')
          .where('followerId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();

      if (followsSnapshot.docs.isEmpty) {
        return [];
      }

      final List<String> followingIds = followsSnapshot.docs
          .map((doc) => doc['followingId'] as String)
          .toList();

      List<ItemModel> allItems = [];

      for (var i = 0; i < followingIds.length; i += 10) {
        final chunk = followingIds.sublist(
            i, i + 10 > followingIds.length ? followingIds.length : i + 10);
            
        final itemsSnapshot = await _itemsRef
            .where('ownerId', whereIn: chunk)
            .where('status', isEqualTo: 'available')
            .get();

        allItems.addAll(
            itemsSnapshot.docs.map((doc) => ItemModel.fromFirestore(doc)));
      }

      allItems.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return allItems.take(5).toList();
    } catch (e) {
      print('Error fetching following items: $e');
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // MOST TRUSTED NEARBY — fetch barang available, shuffle random, filter by category
  // ---------------------------------------------------------------------------

  /// Fetch semua item dengan status "available".
  /// Dikembalikan dalam urutan random (shuffle di client) tanpa algoritma rekomendasi.
  /// Jika [categoryName] diberikan (bukan null / 'All'), filter berdasarkan kategori.
  Stream<List<ItemModel>> watchAvailableItems({String? categoryName}) {
    Query<Map<String, dynamic>> query = _itemsRef.where(
      'status',
      isEqualTo: 'available',
    );

    if (categoryName != null && categoryName != 'All') {
      query = query.where('categoryName', isEqualTo: categoryName);
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return query.snapshots().map((snapshot) {
      final items =
          snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
      if (currentUserId != null) {
        items.removeWhere((item) => item.ownerId == currentUserId);
      }
      // Shuffle random di client — tanpa algoritma, sesuai permintaan
      items.shuffle();
      return items;
    });
  }

  // ---------------------------------------------------------------------------
  // NEW ARRIVALS — 5 item terbaru berdasarkan createdAt DESC
  // ---------------------------------------------------------------------------

  /// Fetch 5 item terbaru berdasarkan `createdAt` descending.
  /// Tidak ada filter status maupun batas waktu — semua item muncul.
  /// Fallback: jika orderBy('createdAt') kosong (dokumen tidak punya field
  /// createdAt), fetch semua lalu sort client-side, ambil [limit] terbaru.
  Stream<List<ItemModel>> watchNewArrivals({int limit = 5}) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return _itemsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ItemModel> items = [];
      if (snapshot.docs.isNotEmpty) {
        items = snapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList();
      } else {
        // Fallback: dokumen tidak punya createdAt — fetch semua, sort client-side
        final all = await _itemsRef.get();
        items =
            all.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
        items.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
      }
      if (currentUserId != null) {
        items.removeWhere((item) => item.ownerId == currentUserId);
      }
      return items.take(limit).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // NEW ARRIVALS FULL LIST — untuk halaman "See More"
  // ---------------------------------------------------------------------------

  /// Fetch semua item diurutkan dari yang terbaru (untuk halaman New Arrivals).
  /// Tidak ada filter status maupun batas waktu.
  /// Fallback: jika orderBy('createdAt') kosong, fetch semua + sort client-side.
  Stream<List<ItemModel>> watchAllNewArrivals() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return _itemsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ItemModel> items = [];
      if (snapshot.docs.isNotEmpty) {
        items = snapshot.docs
            .map((doc) => ItemModel.fromFirestore(doc))
            .toList();
      } else {
        // Fallback: sort client-side
        final all = await _itemsRef.get();
        items =
            all.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
        items.sort((a, b) {
          if (a.createdAt == null && b.createdAt == null) return 0;
          if (a.createdAt == null) return 1;
          if (b.createdAt == null) return -1;
          return b.createdAt!.compareTo(a.createdAt!);
        });
      }
      if (currentUserId != null) {
        items.removeWhere((item) => item.ownerId == currentUserId);
      }
      return items;
    });
  }

  // ---------------------------------------------------------------------------
  // CATEGORIES — fetch distinct category names dari items
  // ---------------------------------------------------------------------------

  /// Fetch semua kategori unik dari collection `item_categories`.
  Future<List<String>> fetchCategoryNames() async {
    try {
      final snapshot = await _db.collection('item_categories').get();
      final names =
          snapshot.docs
              .map((doc) => doc.data()['category'] as String? ?? '')
              .where((name) => name.isNotEmpty)
              .toList();
      return names;
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // SEARCH — fetch semua item available untuk keperluan search client-side
  // ---------------------------------------------------------------------------

  /// Fetch semua item dengan status "available" tanpa filter kategori.
  /// Digunakan oleh SearchSheet untuk filtering client-side (contains/exact/fuzzy).
  Stream<List<ItemModel>> watchSearchableItems() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return _itemsRef
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snap) {
      final items =
          snap.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
      if (currentUserId != null) {
        items.removeWhere((item) => item.ownerId == currentUserId);
      }
      return items;
    });
  }

  // ---------------------------------------------------------------------------
  // OWNER ITEMS — fetch items by ownerId
  // ---------------------------------------------------------------------------

  /// Fetch semua item milik owner tertentu dengan status "available".
  Stream<List<ItemModel>> watchItemsByOwner(String ownerId) {
    return _itemsRef
        .where('ownerId', isEqualTo: ownerId)
        .where('status', isEqualTo: 'available')
        .snapshots()
        .map((snap) {
      return snap.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    });
  }
}
