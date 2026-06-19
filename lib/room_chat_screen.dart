import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'item_detail_screen.dart';
import 'ajukan_sewa_screen.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/models/chat_model.dart';
import 'data/repositories/chat_repository.dart';
import 'image_upload_service.dart';
import 'upload_image_policy.dart';
import 'notification_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'widgets/custom_app_bar.dart';
import 'profile_view_screen.dart';
import 'select_product_screen.dart';

class RoomChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String? itemId;
  final String? itemName;
  final String? itemPhotoUrl;
  final String? initialRoomId;
  final bool autoSendItemCard;

  const RoomChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    this.itemId,
    this.itemName,
    this.itemPhotoUrl,
    this.initialRoomId,
    this.autoSendItemCard = false,
  });

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ScrollController _inputScrollController = ScrollController();
  final ChatRepository _chatRepository = ChatRepository();
  String? _roomId;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final ImageUploadService _imageUploadService = ImageUploadService();
  Stream<List<ChatMessageModel>>? _messagesStream;

  // Cache item ownerIds by item ID to prevent FutureBuilder flickering and repeated fetches.
  final Map<String, String> _itemOwnerCache = {};
  Timer? _presenceHeartbeatTimer;

  String? _actualPartnerName;
  String? _actualPartnerAvatarUrl;
  bool _isUploadingImage = false;
  double? _itemPricePerHour;
  late bool _wasChatAreaActive;
  bool _showItemContextPreview = true;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateMyOnlineStatus(true);
    _startPresenceHeartbeat();
    _wasChatAreaActive = NotificationService.instance.isChatAreaActive;
    NotificationService.instance.setChatAreaActive(true);
    _actualPartnerName = widget.partnerName;
    _actualPartnerAvatarUrl = widget.partnerAvatarUrl;
    _fetchPartnerProfile();
    if (widget.itemId != null) {
      _fetchItemPrice();
    }
    _roomId = widget.initialRoomId;
    if (_roomId == null) {
      _showItemContextPreview = widget.itemId != null;
      _checkExistingRoomAndInit();
    } else {
      _showItemContextPreview = false;
      _chatRepository.markMessagesAsRead(_roomId!);
    }
    _initMessagesStream();
    // Auto-scroll only when input line count changes to prevent typing lag
    int previousLineCount = 1;
    _messageController.addListener(() {
      final text = _messageController.text;
      final lineCount = '\n'.allMatches(text).length + 1;
      if (lineCount != previousLineCount) {
        previousLineCount = lineCount;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  String _formatIndonesianDate(DateTime dt) {
    final months = [
      "Januari", "Februari", "Maret", "April", "Mei", "Juni",
      "Juli", "Agustus", "September", "Oktober", "November", "Desember"
    ];
    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  String _formatIndonesianDateTime(DateTime dt) {
    final months = [
      "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
      "Jul", "Agt", "Sep", "Okt", "Nov", "Des"
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "${dt.day} ${months[dt.month - 1]} $hour:$minute";
  }

  Future<void> _fetchPartnerProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.partnerId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          final fetchedName = data['name'] as String?;
          final fetchedAvatar = (data['profilePhotoUrl'] as String?);
          
          setState(() {
            if (fetchedName != null && fetchedName.isNotEmpty) {
              _actualPartnerName = fetchedName;
            }
            if (fetchedAvatar != null && fetchedAvatar.isNotEmpty) {
              _actualPartnerAvatarUrl = fetchedAvatar;
            }
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchItemPrice() async {
    if (widget.itemId == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('items').doc(widget.itemId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null && data['pricePerHour'] != null) {
          setState(() {
            _itemPricePerHour = (data['pricePerHour'] as num).toDouble();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _checkExistingRoomAndInit() async {
    final existingRoomId = await _chatRepository.findRoom(widget.partnerId);
    String targetRoomId = '';
    
    if (mounted) {
      if (existingRoomId != null) {
        setState(() {
          _roomId = existingRoomId;
          _initMessagesStream();
        });
        targetRoomId = existingRoomId;
        await _chatRepository.markMessagesAsRead(existingRoomId);
      }
    }
    
    bool hasAlreadySentItem = false;
    if (targetRoomId.isNotEmpty && widget.itemId != null) {
      try {
        final msgs = await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(targetRoomId)
            .collection('messages')
            .where('messageType', isEqualTo: 'item_card')
            .get();
        
        for (var doc in msgs.docs) {
          final data = doc.data();
          final text = data['message'] as String? ?? '';
          try {
            final itemMap = json.decode(text) as Map<String, dynamic>;
            if (itemMap['id'] == widget.itemId) {
              hasAlreadySentItem = true;
              break;
            }
          } catch (_) {
            if (text.contains('"id":"${widget.itemId}"') || text.contains('"id": "${widget.itemId}"')) {
              hasAlreadySentItem = true;
              break;
            }
          }
        }
      } catch (_) {}
    }

    if (hasAlreadySentItem) {
      if (mounted) {
        setState(() {
          _showItemContextPreview = false;
        });
      }
    }
  }

  void _initMessagesStream() {
    if (_roomId != null) {
      _messagesStream = _chatRepository.watchMessages(_roomId!);
    } else {
      _messagesStream = null;
    }
  }

  Future<void> _sendMessage({String? customText, String messageType = 'text'}) async {
    final String text = customText ?? _messageController.text.trim();
    if (text.isNotEmpty) {
      if (customText == null) {
        _messageController.clear();
      }
      
      // Kirim item card lebih dulu jika belum pernah dikirim dalam konteks ini
      if (_showItemContextPreview && widget.itemId != null && messageType == 'text') {
        if (mounted) {
          setState(() {
            _showItemContextPreview = false;
          });
        }
        
        bool shouldSendItemCard = true;
        final checkRoomId = _roomId ?? await _chatRepository.findRoom(widget.partnerId);
        if (checkRoomId != null && checkRoomId.isNotEmpty) {
          try {
            final msgs = await FirebaseFirestore.instance
                .collection('chat_rooms')
                .doc(checkRoomId)
                .collection('messages')
                .where('messageType', isEqualTo: 'item_card')
                .get();
            
            for (var doc in msgs.docs) {
              final data = doc.data();
              final msgText = data['message'] as String? ?? '';
              try {
                final itemMap = json.decode(msgText) as Map<String, dynamic>;
                if (itemMap['id'] == widget.itemId) {
                  shouldSendItemCard = false;
                  break;
                }
              } catch (_) {
                if (msgText.contains('"id":"${widget.itemId}"') || msgText.contains('"id": "${widget.itemId}"')) {
                  shouldSendItemCard = false;
                  break;
                }
              }
            }
          } catch (_) {}
        }
        
        if (shouldSendItemCard) {
          await _sendItemCard();
        }
      }

      final roomId = await _chatRepository.sendMessage(
        existingRoomId: _roomId,
        partnerId: widget.partnerId,
        partnerName: _actualPartnerName ?? widget.partnerName,
        partnerAvatarUrl: _actualPartnerAvatarUrl ?? widget.partnerAvatarUrl,
        itemId: widget.itemId,
        itemName: widget.itemName,
        itemPhotoUrl: widget.itemPhotoUrl,
        messageText: text,
        messageType: messageType,
      );

      if (mounted) {
        setState(() {
          if (roomId != null && _roomId == null) {
            _roomId = roomId;
            _initMessagesStream();
          }
          _showItemContextPreview = false;
        });
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendItemCard() async {
    if (widget.itemId == null || widget.itemName == null || widget.itemPhotoUrl == null) return;
    if (_itemPricePerHour == null) {
      await _fetchItemPrice();
    }
    final double computedPrice = (_itemPricePerHour ?? 15000.0) * 24;
    final itemData = {
      'id': widget.itemId,
      'name': widget.itemName,
      'price': 'Rp${computedPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}/hari',
      'image': widget.itemPhotoUrl,
      'status': 'available',
    };
    final String jsonStr = json.encode(itemData);
    await _sendMessage(customText: jsonStr, messageType: 'item_card');
  }

  Future<void> _showAttachmentMenu() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFFFFF8EF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Lampirkan',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pilih apa yang ingin Anda kirimkan.',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Color(0xFF5C635E),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_camera_outlined, color: Color(0xFF012D1D)),
                  ),
                  title: const Text('Kamera', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF012D1D))),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImageWithSource(ImageSource.camera);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: Color(0xFF012D1D)),
                  ),
                  title: const Text('Galeri', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF012D1D))),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndSendImageWithSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F3EE),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory_2_outlined, color: Color(0xFF012D1D)),
                  ),
                  title: const Text('Produk', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, color: Color(0xFF012D1D))),
                  onTap: () async {
                    Navigator.pop(context);
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectProductScreen(partnerId: widget.partnerId),
                      ),
                    );
                    if (result != null && result is String) {
                      await _sendMessage(customText: result, messageType: 'item_card');
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndSendImageWithSource(ImageSource imageSource) async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final processed = await _imageUploadService.pickSingleImageFromSource(
        policy: UploadImagePolicy.chat,
        source: imageSource,
      );

      if (processed != null && mounted) {
        final folderId = _roomId ?? '${_currentUserId}_${widget.partnerId}';
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final storagePath = 'chat_media/$folderId/$fileName.jpg';
        
        final downloadUrl = await _imageUploadService.uploadProcessedImage(
          processed: processed,
          storagePath: storagePath,
        );

        if (downloadUrl.isNotEmpty && mounted) {
          final newRoomId = await _chatRepository.sendMessage(
            existingRoomId: _roomId,
            partnerId: widget.partnerId,
            partnerName: _actualPartnerName ?? widget.partnerName,
            partnerAvatarUrl: _actualPartnerAvatarUrl ?? widget.partnerAvatarUrl,
            itemId: widget.itemId,
            itemName: widget.itemName,
            itemPhotoUrl: widget.itemPhotoUrl,
            messageText: downloadUrl,
            messageType: 'image',
          );

          if (mounted) {
            setState(() {
              if (newRoomId != null && _roomId == null) {
                _roomId = newRoomId;
                _initMessagesStream();
              }
              _showItemContextPreview = false;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(safeImageError(e))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    }
  }

  Future<void> _showReportDialog() async {
    String selectedReason = 'Penipuan';
    final reasons = ['Penipuan', 'Pelecehan', 'Spam', 'Lainnya'];
    
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: const Color(0xFFFFF8EF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF012D1D).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Color(0xFF012D1D),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Laporkan Pengguna',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Pilih alasan utama Anda melaporkan pengguna ini. Laporan Anda akan ditinjau oleh tim kami.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF414844),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      children: reasons.map((reason) {
                        final isSelected = selectedReason == reason;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedReason = reason;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? const Color(0xFF012D1D).withValues(alpha: 0.05) 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF012D1D) 
                                    : const Color(0xFFE5E5E5),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reason,
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                      color: isSelected ? const Color(0xFF012D1D) : const Color(0xFF414844),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF012D1D) : const Color(0xFFC1C8C2),
                                      width: 2,
                                    ),
                                    color: isSelected ? const Color(0xFF012D1D) : Colors.transparent,
                                  ),
                                  child: isSelected 
                                      ? const Icon(Icons.check, size: 12, color: Colors.white) 
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: const BorderSide(color: Color(0xFFC1C8C2)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF414844),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context);
                              await FirebaseFirestore.instance.collection('user_reports').add({
                                'reporterId': _currentUserId,
                                'reportedId': widget.partnerId,
                                'type': 'user_report',
                                'reason': selectedReason,
                                'status': 'pending',
                                'createdAt': FieldValue.serverTimestamp(),
                              });
                              if (!context.mounted) return;
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengguna berhasil dilaporkan'),
                                    backgroundColor: Color(0xFF012D1D),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF012D1D),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Laporkan',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _navigateToAjukanSewa(String itemId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('items').doc(itemId).get();
      if (doc.exists && mounted) {
        final itemData = doc.data();
        if (itemData != null) {
          itemData['id'] = itemId;
          
          // Fix GeoPoint conversion for AjukanSewaScreen
          if (itemData['address'] is Map) {
            final addressMap = itemData['address'] as Map;
            final coordinat = addressMap['coordinat'];
            if (coordinat is GeoPoint) {
              final newAddress = Map<String, dynamic>.from(addressMap);
              newAddress['coordinat'] = {
                'latitude': coordinat.latitude,
                'longitude': coordinat.longitude,
              };
              itemData['address'] = newAddress;
            }
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AjukanSewaScreen(itemData: itemData),
            ),
          );
        }
      }
    } catch (_) {}
  }

  void _updateMyOnlineStatus(bool online) {
    if (_currentUserId != null) {
      FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({
        'isOnline': online,
        'lastSeen': FieldValue.serverTimestamp(),
      }).catchError((_) {});
    }
  }

  void _startPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _updateMyOnlineStatus(true);
    });
  }

  void _stopPresenceHeartbeat() {
    _presenceHeartbeatTimer?.cancel();
    _presenceHeartbeatTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateMyOnlineStatus(true);
      _startPresenceHeartbeat();
    } else {
      _stopPresenceHeartbeat();
      _updateMyOnlineStatus(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopPresenceHeartbeat();
    _updateMyOnlineStatus(false);
    NotificationService.instance.setChatAreaActive(_wasChatAreaActive);
    _messageController.dispose();
    _scrollController.dispose();
    _inputScrollController.dispose();
    super.dispose();
  }

  List<dynamic> _buildListItems(List<ChatMessageModel> messages) {
    final List<dynamic> items = [];
    if (messages.isEmpty) return items;

    DateTime? lastDate;
    for (var message in messages) {
      if (message.sentAt != null) {
        final msgDate = DateTime(message.sentAt!.year, message.sentAt!.month, message.sentAt!.day);
        if (lastDate == null || msgDate != lastDate) {
          lastDate = msgDate;
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final yesterday = today.subtract(const Duration(days: 1));
          
          String dateText = "";
          if (msgDate == today) {
            dateText = "Hari ini";
          } else if (msgDate == yesterday) {
            dateText = "Kemarin";
          } else {
            dateText = _formatIndonesianDate(message.sentAt!);
          }
          items.add(dateText);
        }
      }
      items.add(message);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF012D1D),
      appBar: CustomAppBar(
        titleWidget: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileViewScreen(
                  ownerId: widget.partnerId,
                  ownerName: _actualPartnerName ?? widget.partnerName,
                  avatarImage: _actualPartnerAvatarUrl != null && _actualPartnerAvatarUrl!.isNotEmpty
                      ? _imageUploadService.buildImageProvider(_actualPartnerAvatarUrl!)
                      : const AssetImage('assets/images/no-profile-picture-icon.webp'),
                ),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _actualPartnerAvatarUrl != null && _actualPartnerAvatarUrl!.isNotEmpty
                      ? Image(
                          image: _imageUploadService.buildImageProvider(_actualPartnerAvatarUrl!),
                          fit: BoxFit.cover,
                        )
                      : Image.asset(
                          'assets/images/no-profile-picture-icon.webp',
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _actualPartnerName ?? widget.partnerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF012D1D),
                      ),
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(widget.partnerId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return const Text(
                            "Offline",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }
                        
                        final data = snapshot.data!.data() as Map<String, dynamic>?;
                        final isOnline = data?['isOnline'] as bool? ?? false;
                        final lastSeen = data?['lastSeen'] as Timestamp?;
                        
                        bool onlineActive = false;
                        if (isOnline && lastSeen != null) {
                          final lastSeenDate = lastSeen.toDate();
                          final now = DateTime.now();
                          final difference = now.difference(lastSeenDate);
                          // User is considered online if marked online AND heartbeat is within last 2 minutes (120s)
                          if (difference.inSeconds.abs() < 120) {
                            onlineActive = true;
                          }
                        }
                        
                        if (onlineActive) {
                          return const Text(
                            "Online",
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xFF10B981),
                            ),
                          );
                        } else {
                          String subtitle = "Offline";
                          if (lastSeen != null) {
                            final lastSeenDate = lastSeen.toDate();
                            final now = DateTime.now();
                            final difference = now.difference(lastSeenDate);
                            if (difference.inMinutes < 1) {
                              subtitle = "Baru saja aktif";
                            } else if (difference.inMinutes < 60) {
                              subtitle = "Aktif ${difference.inMinutes} menit lalu";
                            } else if (difference.inHours < 24) {
                              subtitle = "Aktif ${difference.inHours} jam lalu";
                            } else {
                              subtitle = "Aktif ${_formatIndonesianDateTime(lastSeenDate)}";
                            }
                          }
                          return Text(
                            subtitle,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF012D1D)),
            onPressed: _showReportDialog,
          ),
        ],
      ),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height,
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height,
            child: Container(
              color: const Color(0xFF012D1D).withValues(alpha: 0.8),
            ),
          ),
          SafeArea(
            top: false,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: _roomId == null
                      ? Column(
                          children: [
                            SizedBox(height: MediaQuery.of(context).padding.top + 70 + 8),
                            _buildSecurityWarningBanner(),
                            const Spacer(),
                            const Center(
                              child: Text(
                                "Kirim pesan pertama Anda!",
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                            const Spacer(),
                          ],
                        )
                      : StreamBuilder<List<ChatMessageModel>>(
                          stream: _messagesStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(color: Colors.white));
                            }
                            
                            final messages = snapshot.data ?? [];
                            final listItems = _buildListItems(messages);
                            
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (_scrollController.hasClients) {
                                if (_isFirstLoad) {
                                  _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                                  _isFirstLoad = false;
                                } else {
                                  final maxScroll = _scrollController.position.maxScrollExtent;
                                  final currentOffset = _scrollController.offset;
                                  if (maxScroll - currentOffset < 300) {
                                    _scrollController.animateTo(
                                      maxScroll,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                }
                              }
                            });

                            return ListView.builder(
                              controller: _scrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.only(
                                left: 16,
                                right: 16,
                                top: MediaQuery.of(context).padding.top + 70 + 8,
                                bottom: 8,
                              ),
                              itemCount: listItems.length + 1, // Warning banner + items
                              itemBuilder: (context, index) {
                                if (index == 0) {
                                  return _buildSecurityWarningBanner();
                                }
                                final item = listItems[index - 1];
                                if (item is String) {
                                  return _buildDateSeparator(item);
                                }
                                return _buildBubbleRow(item as ChatMessageModel);
                              },
                            );
                          },
                        ),
                ),
                _buildBottomInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityWarningBanner() {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Text(
            "Hati-hati penipuan! Mohon tidak bertransaksi di luar aplikasi SewaIn Aja dan tidak memberikan data pribadi kepada penjual, seperti nomor HP dan alamat. Tetap berinteraksi melalui aplikasi SewaIn Aja, ya.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              fontSize: 11,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () {},
            child: const Text(
              "Baca Panduan Keamanan",
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: Color(0xFFC1ECD4),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(String dateText) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          dateText,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w500,
            fontSize: 12,
            color: Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildBubbleRow(ChatMessageModel message) {
    final bool isMe = message.senderId == _currentUserId;
    
    String timeString = "";
    if (message.sentAt != null) {
      timeString = DateFormat('HH:mm').format(message.sentAt!);
    }

    if (message.messageType == 'item_card') {
      return _buildItemCardBubble(message, isMe, timeString);
    } else if (message.messageType == 'image') {
      return _buildImageMessageBubble(message, isMe, timeString);
    } else {
      return _buildTextMessageBubble(message, isMe, timeString);
    }
  }

  Widget _buildTextMessageBubble(ChatMessageModel message, bool isMe, String timeString) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFC1ECD4) : const Color(0xFFD1D5DB),
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.message,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  color: Color(0xFF012D1D),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeString,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      color: const Color(0xFF012D1D).withValues(alpha: 0.5),
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.done_all,
                      size: 14,
                      color: message.isRead ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageMessageBubble(ChatMessageModel message, bool isMe, String timeString) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFFC1ECD4) : const Color(0xFFD1D5DB),
            borderRadius: isMe
                ? const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  )
                : const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImageViewer(imageUrl: message.message),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    message.message,
                    width: 200,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 150,
                        color: Colors.black.withValues(alpha: 0.05),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF012D1D),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 200,
                      height: 150,
                      color: Colors.black.withValues(alpha: 0.05),
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_rounded,
                          color: Colors.grey,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeString,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        color: const Color(0xFF012D1D).withValues(alpha: 0.5),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.done_all,
                        size: 14,
                        color: message.isRead ? const Color(0xFF10B981) : Colors.grey,
                      ),
                    ]
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemCardBubble(ChatMessageModel message, bool isMe, String timeString) {
    Map<String, dynamic> item = {};
    try {
      item = json.decode(message.message) as Map<String, dynamic>;
    } catch (_) {
      item = {
        'id': widget.itemId ?? '',
        'name': widget.itemName ?? '',
        'price': 'Loading...',
        'image': widget.itemPhotoUrl ?? '',
        'status': 'available',
      };
    }

    final String itemId = item['id']?.toString() ?? '';
    final String name = item['name']?.toString() ?? '';
    final String price = item['price']?.toString() ?? '';
    final String image = item['image']?.toString() ?? '';
    final String status = item['status']?.toString() ?? 'available';
    final bool isAvailable = status.toLowerCase() == 'available';

    // Retrieve or fetch item owner
    final String? ownerId = _itemOwnerCache[itemId];
    if (itemId.isNotEmpty && !_itemOwnerCache.containsKey(itemId)) {
      _itemOwnerCache[itemId] = 'loading'; // Mark to prevent duplicate fetches
      FirebaseFirestore.instance.collection('items').doc(itemId).get().then((doc) {
        if (doc.exists && mounted) {
          final data = doc.data();
          final owner = data?['ownerId'] as String? ?? '';
          setState(() {
            _itemOwnerCache[itemId] = owner;
          });
        } else if (mounted) {
          setState(() {
            _itemOwnerCache[itemId] = ''; // Handle non-existent doc
          });
        }
      }).catchError((_) {
        if (mounted) {
          setState(() {
            _itemOwnerCache.remove(itemId); // Retry next time
          });
        }
      });
    }

    final bool isOwnItem = ownerId != null && ownerId != 'loading' && ownerId == _currentUserId;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF012D1D).withValues(alpha: 0.1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Product row clickable to details
              GestureDetector(
                onTap: () {
                  if (itemId.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDetailScreen(itemId: itemId),
                      ),
                    );
                  }
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: image.isNotEmpty
                              ? Image(
                                  image: _imageUploadService.buildImageProvider(image),
                                  width: 64,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => Container(
                                    width: 64,
                                    height: 64,
                                    color: const Color(0xFFF5F5F5),
                                    child: const Icon(Icons.image, size: 24, color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  width: 64,
                                  height: 64,
                                  color: const Color(0xFFF5F5F5),
                                  child: const Icon(Icons.image, size: 24, color: Colors.grey),
                                ),
                        ),
                        if (!isAvailable)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                "Stok habis",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF012D1D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF012D1D),
                            ),
                          ),

                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isOwnItem && ownerId != null && ownerId != 'loading')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _navigateToAjukanSewa(itemId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF012D1D),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Sewa Sekarang",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildBottomInputArea() {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildItemContextPreview(),
        _buildQuickReplies(),
        Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFDF9F4),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 12,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMainInputRow(),
              // Fill the system nav bar area so there's no gap on any device
              SizedBox(height: bottomPadding > 0 ? bottomPadding : 16.0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemContextPreview() {
    if (!_showItemContextPreview || widget.itemName == null || widget.itemName!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (widget.itemId != null && widget.itemId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemDetailScreen(itemId: widget.itemId!),
                  ),
                );
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: (widget.itemPhotoUrl != null && widget.itemPhotoUrl!.isNotEmpty)
                  ? Image(
                      image: _imageUploadService.buildImageProvider(widget.itemPhotoUrl!),
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        width: 32,
                        height: 32,
                        color: const Color(0xFFF5F5F5),
                        child: const Icon(Icons.image, size: 16, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 32,
                      height: 32,
                      color: const Color(0xFFF5F5F5),
                      child: const Icon(Icons.image, size: 16, color: Colors.grey),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (widget.itemId != null && widget.itemId!.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemDetailScreen(itemId: widget.itemId!),
                    ),
                  );
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.itemName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _itemPricePerHour != null
                        ? 'Rp${((_itemPricePerHour ?? 15000.0) * 24).toStringAsFixed(0).replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (Match m) => "${m[1]}.")}/hari'
                        : 'Loading...',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFF012D1D)),
            onPressed: () {
              setState(() {
                _showItemContextPreview = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickReplies() {
    if (!_showItemContextPreview) {
      return const SizedBox.shrink();
    }
    final replies = [
      "Hai, barang ini ready?",
      "Bisa disewa hari ini?",
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: replies.length,
        itemBuilder: (context, index) {
          final reply = replies[index];
          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: ActionChip(
              label: Text(
                reply,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: Color(0xFF414844),
                ),
              ),
              backgroundColor: const Color(0xFFD1D5DB),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide.none,
              ),
              onPressed: () => _sendMessage(customText: reply),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainInputRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF012D1D),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: _showAttachmentMenu,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF012D1D),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: ScrollbarTheme(
                      data: ScrollbarThemeData(
                        thumbColor: WidgetStateProperty.all(
                          Colors.white.withValues(alpha: 0.5),
                        ),
                        trackColor: WidgetStateProperty.all(
                          Colors.white.withValues(alpha: 0.15),
                        ),
                        trackVisibility: WidgetStateProperty.all(true),
                        thickness: WidgetStateProperty.all(3),
                        radius: const Radius.circular(8),
                      ),
                      child: Scrollbar(
                        controller: _inputScrollController,
                        thumbVisibility: true,
                        interactive: true,
                        child: TextField(
                          controller: _messageController,
                          scrollController: _inputScrollController,
                          minLines: 1,
                          maxLines: 6,
                          textInputAction: TextInputAction.newline,
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          decoration: const InputDecoration(
                            hintText: "Ketik pesan...",
                            hintStyle: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: Color(0xFF6B9E87),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_isUploadingImage) ...
                    [
                      const SizedBox(width: 8),
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ]
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF012D1D),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: () => _sendMessage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> {
  bool _isDownloading = false;

  Future<void> _downloadImage() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final response = await http.get(Uri.parse(widget.imageUrl));
      if (response.statusCode == 200) {
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        if (directory != null) {
          final fileName = 'SewainAja_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final filePath = '${directory.path}/$fileName';
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gambar berhasil disimpan ke: $filePath'),
                backgroundColor: const Color(0xFF012D1D),
              ),
            );
          }
        } else {
          throw Exception('Gagal mengakses penyimpanan lokal.');
        }
      } else {
        throw Exception('Gagal mengunduh gambar (Status: ${response.statusCode})');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh gambar: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download_rounded, color: Colors.white),
                  onPressed: _downloadImage,
                  tooltip: 'Unduh Gambar',
                ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          clipBehavior: Clip.none,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
