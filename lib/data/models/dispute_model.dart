class DisputeModel {
  final String id;
  final String transactionId;
  final String reportedBy;
  final String description;
  final String category;
  final String? evidenceUrl;
  final List<String> evidenceUrls;
  final String status;
  final String? resolutionNote;
  final String? resolvedBy;
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final DateTime? deadlineAt;
  final bool isOverdue;

  // Respondent / Terlapor fields
  final String? respondentId;
  final String? respondentName;
  final String? respondentDescription;
  final List<String> respondentEvidenceUrls;
  final DateTime? respondentRespondedAt;

  // Denormalized/Related fields
  final String reporterName;
  final String renterName;
  final List<String> itemNames;
  final List<TransactionEvidenceModel> transactionEvidences;

  DisputeModel({
    required this.id,
    required this.transactionId,
    required this.reportedBy,
    required this.description,
    required this.category,
    this.evidenceUrl,
    required this.evidenceUrls,
    required this.status,
    this.resolutionNote,
    this.resolvedBy,
    this.createdAt,
    this.resolvedAt,
    this.deadlineAt,
    required this.isOverdue,
    this.respondentId,
    this.respondentName,
    this.respondentDescription,
    required this.respondentEvidenceUrls,
    this.respondentRespondedAt,
    required this.reporterName,
    required this.renterName,
    required this.itemNames,
    this.transactionEvidences = const [],
  });

  factory DisputeModel.fromJson(Map<String, dynamic> json) {
    return DisputeModel(
      id: json['id'] ?? '',
      transactionId: json['transactionId'] ?? '',
      reportedBy: json['reportedBy'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      evidenceUrl: json['evidenceUrl'],
      evidenceUrls: List<String>.from(json['evidenceUrls'] ?? []),
      status: json['status'] ?? 'open',
      resolutionNote: json['resolutionNote'],
      resolvedBy: json['resolvedBy'],
      createdAt: _parseDate(json['createdAt']),
      resolvedAt: _parseDate(json['resolvedAt']),
      deadlineAt: _parseDate(json['deadlineAt']),
      isOverdue: json['isOverdue'] ?? false,
      respondentId: json['respondentId'],
      respondentName: json['respondentName'],
      respondentDescription: json['respondentDescription'],
      respondentEvidenceUrls: List<String>.from(json['respondentEvidenceUrls'] ?? []),
      respondentRespondedAt: _parseDate(json['respondentRespondedAt']),
      reporterName: json['reporterName'] ?? '',
      renterName: json['renterName'] ?? '',
      itemNames: List<String>.from(json['itemNames'] ?? []),
      transactionEvidences: (json['transactionEvidences'] as List<dynamic>?)
              ?.map((e) => TransactionEvidenceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) {
      return DateTime.tryParse(val)?.toLocal();
    }
    if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    }
    if (val is Map) {
      final seconds = val['_seconds'] ?? val['seconds'];
      if (seconds != null && seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000).toLocal();
      }
    }
    return null;
  }
}

class TransactionEvidenceModel {
  final String id;
  final String uploaderId;
  final String type; // 'before' | 'after'
  final String mediaUrl;
  final String mediaType; // 'photo' | 'video'
  final DateTime? uploadedAt;

  TransactionEvidenceModel({
    required this.id,
    required this.uploaderId,
    required this.type,
    required this.mediaUrl,
    required this.mediaType,
    this.uploadedAt,
  });

  factory TransactionEvidenceModel.fromJson(Map<String, dynamic> json) {
    return TransactionEvidenceModel(
      id: json['id'] ?? '',
      uploaderId: json['uploaderId'] ?? '',
      type: json['type'] ?? 'before',
      mediaUrl: json['mediaUrl'] ?? '',
      mediaType: json['mediaType'] ?? 'photo',
      uploadedAt: DisputeModel._parseDate(json['uploadedAt']),
    );
  }
}
