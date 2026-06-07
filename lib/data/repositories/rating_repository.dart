import 'package:cloud_firestore/cloud_firestore.dart';

class RatingRepository {
  RatingRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _ratingsRef =>
      _db.collection('ratings');

  /// Fetch list review untuk owner tertentu
  Stream<List<Map<String, dynamic>>> watchOwnerReviews(String ownerId, {int limit = 5}) {
    return _ratingsRef
        .where('toUserId', isEqualTo: ownerId)
        .where('ratedAs', isEqualTo: 'owner')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
}
