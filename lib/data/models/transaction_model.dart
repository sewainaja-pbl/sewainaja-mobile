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
  final AdendumRequestModel? adendumRequest;

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
    this.adendumRequest,
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
      adendumRequest: json['adendumRequest'] != null
          ? AdendumRequestModel.fromJson(json['adendumRequest'] as Map<String, dynamic>)
          : null,
    );
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is String) {
      return DateTime.tryParse(val)?.toLocal();
    }
    if (val is Timestamp) {
      return val.toDate().toLocal();
    }
    if (val is int) {
      // Assuming milliseconds since epoch if it's a number
      return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    }
    if (val is Map) {
      final seconds = val['_seconds'] ?? val['seconds'];
      if (seconds != null && seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000).toLocal();
      }
      final millis = val['_milliseconds'] ?? val['milliseconds'];
      if (millis != null && millis is num) {
        return DateTime.fromMillisecondsSinceEpoch(millis.toInt()).toLocal();
      }
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

class AdendumRequestModel {
  final DateTime? newEndDate;
  final double additionalCost;
  final String status;
  final String? paymentMethod;
  final String? paymentStatus;
  final DateTime? createdAt;

  AdendumRequestModel({
    this.newEndDate,
    required this.additionalCost,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.createdAt,
  });

  factory AdendumRequestModel.fromJson(Map<String, dynamic> json) {
    return AdendumRequestModel(
      newEndDate: TransactionModel._parseDate(json['newEndDate']),
      additionalCost: (json['additionalCost'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      createdAt: TransactionModel._parseDate(json['createdAt']),
    );
  }
}
