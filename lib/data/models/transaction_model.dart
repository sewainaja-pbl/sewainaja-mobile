import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String renterId;
  final String ownerId;
  final double totalPrice;
  final int totalItems;
  final String status;
  final bool isOverdue;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? checkinAt;
  final DateTime? checkoutAt;
  final String renterName;
  final String ownerName;
  final List<TransactionDetailModel> details;

  TransactionModel({
    required this.id,
    required this.renterId,
    required this.ownerId,
    required this.totalPrice,
    required this.totalItems,
    required this.status,
    required this.isOverdue,
    this.createdAt,
    this.updatedAt,
    this.checkinAt,
    this.checkoutAt,
    required this.renterName,
    required this.ownerName,
    this.details = const [],
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      renterId: json['renterId'] ?? '',
      ownerId: json['ownerId'] ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      totalItems: json['totalItems'] ?? 0,
      status: json['status'] ?? 'pending',
      isOverdue: json['isOverdue'] ?? false,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      checkinAt: _parseDate(json['checkinAt']),
      checkoutAt: _parseDate(json['checkoutAt']),
      renterName: json['renterName'] ?? 'Renter',
      ownerName: json['ownerName'] ?? 'Owner',
      details: (json['details'] as List<dynamic>?)
              ?.map((d) => TransactionDetailModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) {
      return DateTime.tryParse(val);
    }
    if (val is Timestamp) {
      return val.toDate();
    }
    if (val is int) {
      // Assuming milliseconds since epoch if it's a number
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    return null;
  }
}

class TransactionDetailModel {
  final String id;
  final String itemId;
  final DateTime? startDate;
  final DateTime? endDate;
  final double priceAtBooking;
  final String itemNameSnapshot;
  final String itemPhotoUrlSnapshot;
  final double subtotal;

  TransactionDetailModel({
    required this.id,
    required this.itemId,
    this.startDate,
    this.endDate,
    required this.priceAtBooking,
    required this.itemNameSnapshot,
    required this.itemPhotoUrlSnapshot,
    required this.subtotal,
  });

  factory TransactionDetailModel.fromJson(Map<String, dynamic> json) {
    return TransactionDetailModel(
      id: json['id'] ?? '',
      itemId: json['itemId'] ?? '',
      startDate: TransactionModel._parseDate(json['startDate']),
      endDate: TransactionModel._parseDate(json['endDate']),
      priceAtBooking: (json['priceAtBooking'] as num?)?.toDouble() ?? 0.0,
      itemNameSnapshot: json['itemNameSnapshot'] ?? 'Item',
      itemPhotoUrlSnapshot: json['itemPhotoUrlSnapshot'] ?? '',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
