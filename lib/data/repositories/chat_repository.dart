import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/chat_model.dart';
class ChatRepository {
  ChatRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _chatRoomsRef =>
      _db.collection('chat_rooms');

  /// Mendengarkan list room chat di mana `participantIds` mengandung user saat ini.
  Stream<List<ChatRoomModel>> watchMyChatRooms() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _chatRoomsRef
        .where('participantIds', arrayContains: currentUserId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatRoomModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Mendengarkan subcollection `messages` dari suatu room.
  Stream<List<ChatMessageModel>> watchMessages(String roomId) {
    return _chatRoomsRef
        .doc(roomId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatMessageModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Mencari room chat yang sudah ada antara currentUser dan partnerId (1-on-1).
  Future<String?> findRoom(String partnerId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return null;

    try {
      final snapshot = await _chatRoomsRef
          .where('participantIds', arrayContains: currentUserId)
          .get();

      for (var doc in snapshot.docs) {
        final participantIds = List<String>.from(doc.data()['participantIds'] as List? ?? []);
        if (participantIds.contains(partnerId)) {
          return doc.id;
        }
      }
    } catch (e) {
      print("Error finding room: $e");
    }
    return null;
  }

  /// Mengirim pesan. Jika room belum ada, buat baru.
  Future<String?> sendMessage({
    String? existingRoomId,
    required String partnerId,
    required String partnerName,
    String? partnerAvatarUrl,
    String? itemId,
    String? itemName,
    String? itemPhotoUrl,
    required String messageText,
    String messageType = 'text',
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;
    final currentUserId = currentUser.uid;
    
    // Fetch actual user data from Firestore users collection
    String currentUserName = currentUser.displayName ?? "User";
    String? currentUserAvatar = currentUser.photoURL;
    try {
      final userDoc = await _db.collection('users').doc(currentUserId).get();
      if (userDoc.exists) {
        final userData = userDoc.data();
        if (userData != null) {
          currentUserName = (userData['name'] as String?) ?? currentUserName;
          currentUserAvatar = (userData['profilePhotoUrl'] as String?) ?? currentUserAvatar;
        }
      }
    } catch (_) {}

    // Also fetch partner's actual profile data
    String actualPartnerName = partnerName;
    String? actualPartnerAvatar = partnerAvatarUrl;
    try {
      final partnerDoc = await _db.collection('users').doc(partnerId).get();
      if (partnerDoc.exists) {
        final partnerData = partnerDoc.data();
        if (partnerData != null) {
          actualPartnerName = (partnerData['name'] as String?) ?? partnerName;
          actualPartnerAvatar = (partnerData['profilePhotoUrl'] as String?) ?? partnerAvatarUrl;
        }
      }
    } catch (_) {}

    try {
      String roomId = existingRoomId ?? await findRoom(partnerId) ?? '';
      
      final batch = _db.batch();
      final now = FieldValue.serverTimestamp();

      String displayLastMessage = messageText;
      if (messageType == 'item_card') {
        displayLastMessage = '📦 ${itemName ?? "Barang"}';
      } else if (messageType == 'image') {
        displayLastMessage = '📷 Foto';
      } else if (itemName != null && messageText.isNotEmpty) {
        // Menambahkan nama produk di depan teks agar sesuai dengan permintaan user
        displayLastMessage = '$itemName : $messageText';
      }

      if (roomId.isEmpty) {
        // Create new room
        final newRoomRef = _chatRoomsRef.doc();
        roomId = newRoomRef.id;

        final participants = {
          currentUserId: {
            'name': currentUserName,
            if (currentUserAvatar != null) 'avatarUrl': currentUserAvatar,
          },
          partnerId: {
            'name': actualPartnerName,
            if (actualPartnerAvatar != null) 'avatarUrl': actualPartnerAvatar,
          }
        };

        batch.set(newRoomRef, {
          'participantIds': [currentUserId, partnerId],
          if (itemId != null) 'itemId': itemId,
          'transactionId': null,
          'lastMessage': displayLastMessage,
          'lastMessageAt': now,
          'lastMessageSender': currentUserId,
          'createdBy': currentUserId,
          'createdAt': now,
          'participants': participants,
          if (itemName != null) 'itemName': itemName,
          if (itemPhotoUrl != null) 'itemPhotoUrl': itemPhotoUrl,
        });
      } else {
        // Update existing room
        final roomRef = _chatRoomsRef.doc(roomId);
        batch.update(roomRef, {
          'lastMessage': displayLastMessage,
          'lastMessageAt': now,
          'lastMessageSender': currentUserId,
        });
      }

      // Add message
      final newMessageRef = _chatRoomsRef.doc(roomId).collection('messages').doc();
      batch.set(newMessageRef, {
        'senderId': currentUserId,
        'message': messageText,
        'messageType': messageType,
        'isRead': false,
        'sentAt': now,
        'deletedAt': null,
      });

      // Parse item_card JSON for notification
      String notifBody = messageText;
      String? notifImageUrl;

      if (messageType == 'item_card') {
        try {
          final decoded = jsonDecode(messageText);
          final itemNameFromData = decoded['name'] ?? "Barang";
          notifBody = '📦 $itemNameFromData';
          notifImageUrl = decoded['image'];
        } catch (_) {
          notifBody = '📦 Barang';
        }
      } else if (messageType == 'image') {
        notifBody = '📷 Foto';
        notifImageUrl = messageText;
      }

      // Create notification for the partner
      final newNotificationRef = _db.collection('notifications').doc();
      batch.set(newNotificationRef, {
        'userId': partnerId,
        'type': 'reminder',
        'title': 'Pesan baru dari $currentUserName',
        'body': notifBody,
        if (notifImageUrl != null) 'imageUrl': notifImageUrl,
        'chatPartnerId': currentUserId,
        'chatPartnerName': currentUserName,
        'isRead': false,
        'isSent': false, // Cloud Function trigger akan set true setelah kirim FCM
        'transactionId': null,
        'scheduledAt': null,
        'createdAt': now,
        'updatedAt': now,
      });

      await batch.commit();
      return roomId;
    } catch (e) {
      print("Error sending message: $e");
      return null;
    }
  }

  /// Update status isRead = true untuk pesan dari partner
  Future<void> markMessagesAsRead(String roomId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      final unreadMessages = await _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      if (unreadMessages.docs.isEmpty) return;

      final batch = _db.batch();
      bool hasUpdates = false;

      for (var doc in unreadMessages.docs) {
        if (doc.data()['senderId'] != currentUserId) {
          batch.update(doc.reference, {'isRead': true});
          hasUpdates = true;
        }
      }

      if (hasUpdates) {
        await batch.commit();
      }
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadImage(File file, String roomId) async {
    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_media')
          .child(roomId)
          .child('$fileName.jpg');
      
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  /// Get unread message count for a specific room (one-time fetch)
  Future<int> getUnreadCount(String roomId) async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return 0;

    try {
      final snapshot = await _chatRoomsRef
          .doc(roomId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        if (doc.data()['senderId'] != currentUserId) {
          count++;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  /// Stream real-time unread message count for a specific room
  Stream<int> watchUnreadCount(String roomId) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return Stream.value(0);

    return _chatRoomsRef
        .doc(roomId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      int count = 0;
      for (var doc in snapshot.docs) {
        if (doc.data()['senderId'] != currentUserId) {
          count++;
        }
      }
      return count;
    });
  }
}
