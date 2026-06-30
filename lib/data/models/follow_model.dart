class FollowModel {
  final String id;
  final String followerId;
  final String followingId;
  final DateTime? createdAt;

  FollowModel({
    required this.id,
    required this.followerId,
    required this.followingId,
    this.createdAt,
  });

  factory FollowModel.fromJson(Map<String, dynamic> json) {
    return FollowModel(
      id: json['id'] ?? '',
      followerId: json['followerId'] ?? '',
      followingId: json['followingId'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'followerId': followerId,
      'followingId': followingId,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
}
