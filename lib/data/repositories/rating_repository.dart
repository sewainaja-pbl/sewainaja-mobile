import 'package:cloud_firestore/cloud_firestore.dart';

class RatingRepository {
  RatingRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _ratingsRef =>
      _db.collection('ratings');

  /// Fetch list review untuk owner tertentu
  Stream<List<Map<String, dynamic>>> watchOwnerReviews(String ownerId, {int? limit}) {
    print('[RatingRepository] watchOwnerReviews called for ownerId: "$ownerId", limit: $limit');
    final Query<Map<String, dynamic>> query = _ratingsRef
        .where('toUserId', isEqualTo: ownerId)
        .where('ratedAs', isEqualTo: 'owner');

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      print('[RatingRepository] watchOwnerReviews retrieved ${list.length} raw docs for ownerId: "$ownerId"');

      // Sort by createdAt descending in memory
      list.sort((a, b) {
        final aTime = a['createdAt'] as Timestamp?;
        final bTime = b['createdAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      if (limit != null && list.length > limit) {
        return list.sublist(0, limit);
      }
      return list;
    });
  }
}
