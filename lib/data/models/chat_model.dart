import 'package:cloud_firestore/cloud_firestore.dart';

class ChatParticipantInfo {
  final String name;
  final String? avatarUrl;

  const ChatParticipantInfo({
    required this.name,
    this.avatarUrl,
  });

  factory ChatParticipantInfo.fromMap(Map<String, dynamic> map) {
    return ChatParticipantInfo(
      name: map['name'] as String? ?? '',
      avatarUrl: map['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }
}

class ChatRoomModel {
  final String id;
  final List<String> participantIds;
  final String? itemId;
  final String? transactionId;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastMessageSender;
  final DateTime? createdAt;
  final Map<String, ChatParticipantInfo> participants;
  final String? itemName;
  final String? itemPhotoUrl;
  final String? createdBy;

  const ChatRoomModel({
    required this.id,
    required this.participantIds,
    this.itemId,
    this.transactionId,
    required this.lastMessage,
    this.lastMessageAt,
    required this.lastMessageSender,
    this.createdAt,
    required this.participants,
    this.itemName,
    this.itemPhotoUrl,
    this.createdBy,
  });

  factory ChatRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final participantsMap = data['participants'] as Map<String, dynamic>? ?? {};
    final parsedParticipants = <String, ChatParticipantInfo>{};
    participantsMap.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        parsedParticipants[key] = ChatParticipantInfo.fromMap(value);
      }
    });

    return ChatRoomModel(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] as List? ?? []),
      itemId: data['itemId'] as String?,
      transactionId: data['transactionId'] as String?,
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt: (data['lastMessageAt'] as Timestamp?)?.toDate(),
      lastMessageSender: data['lastMessageSender'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      participants: parsedParticipants,
      itemName: data['itemName'] as String?,
      itemPhotoUrl: data['itemPhotoUrl'] as String?,
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> pMap = {};
    participants.forEach((key, value) {
      pMap[key] = value.toMap();
    });

    return {
      'id': id,
      'participantIds': participantIds,
      if (itemId != null) 'itemId': itemId,
      if (transactionId != null) 'transactionId': transactionId,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,
      'lastMessageSender': lastMessageSender,
      'createdAt': createdAt,
      'participants': pMap,
      if (itemName != null) 'itemName': itemName,
      if (itemPhotoUrl != null) 'itemPhotoUrl': itemPhotoUrl,
      if (createdBy != null) 'createdBy': createdBy,
    };
  }
}

class ChatMessageModel {
  final String id;
  final String senderId;
  final String message;
  final String messageType; // "text" | "image"
  final bool isRead;
  final DateTime? sentAt;
  final DateTime? deletedAt;

  const ChatMessageModel({
    required this.id,
    required this.senderId,
    required this.message,
    this.messageType = 'text',
    this.isRead = false,
    this.sentAt,
    this.deletedAt,
  });

  factory ChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessageModel(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      message: data['message'] as String? ?? '',
      messageType: data['messageType'] as String? ?? 'text',
      isRead: data['isRead'] as bool? ?? false,
      sentAt: (data['sentAt'] as Timestamp?)?.toDate(),
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'message': message,
      'messageType': messageType,
      'isRead': isRead,
      'sentAt': sentAt,
      'deletedAt': deletedAt,
    };
  }
}
