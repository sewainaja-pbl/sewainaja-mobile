import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../auth_session_service.dart';

class UserRepository {
  UserRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;
  final AuthSessionService _authService = const AuthSessionService();

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _db.collection('users');

  /// Ambil profil public user berdasarkan userId
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _usersRef.doc(userId).get();
      if (doc.exists) {
        final data = Map<String, dynamic>.from(doc.data()!);
        try {
          final countQuery = await _db.collection('follows').where('followingId', isEqualTo: userId).count().get();
          data['followersCount'] = countQuery.count ?? 0;
        } catch (e) {
          data['followersCount'] = 0;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  /// Follow a user
  Future<void> followUser(String followingId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final followId = '${currentUserId}_$followingId';
    await _db.collection('follows').doc(followId).set({
      'followerId': currentUserId,
      'followingId': followingId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Unfollow a user
  Future<void> unfollowUser(String followingId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final followId = '${currentUserId}_$followingId';
    await _db.collection('follows').doc(followId).delete();
  }

  /// Get follow status
  Future<bool> getFollowStatus(String followingId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return false;
    }

    final followId = '${currentUserId}_$followingId';
    final doc = await _db.collection('follows').doc(followId).get();
    return doc.exists;
  }
}
