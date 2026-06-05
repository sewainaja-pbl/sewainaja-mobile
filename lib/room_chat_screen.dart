import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'item_detail_screen.dart';

import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/models/chat_model.dart';
import 'data/repositories/chat_repository.dart';
import 'image_upload_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class RoomChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  final String? partnerAvatarUrl;
  final String itemId;
  final String itemName;
  final String itemPhotoUrl;
  final String? initialRoomId;

  const RoomChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
    this.partnerAvatarUrl,
    required this.itemId,
    required this.itemName,
    required this.itemPhotoUrl,
    this.initialRoomId,
  });

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatRepository _chatRepository = ChatRepository();
  String? _roomId;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final ImageUploadService _imageUploadService = ImageUploadService();

  String? _actualPartnerName;
  String? _actualPartnerAvatarUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _actualPartnerName = widget.partnerName;
    _actualPartnerAvatarUrl = widget.partnerAvatarUrl;
    _fetchPartnerProfile();
    _roomId = widget.initialRoomId;
    if (_roomId == null) {
      _checkExistingRoom();
    } else {
      _chatRepository.markMessagesAsRead(_roomId!);
    }
  }

  Future<void> _fetchPartnerProfile() async {
    try {
      print('DEBUG: Fetching partner profile for partnerId: ${widget.partnerId}');
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.partnerId).get();
      print('DEBUG: Document exists: ${doc.exists}');
      if (doc.exists && mounted) {
        final data = doc.data();
        print('DEBUG: User data keys: ${data?.keys.toList()}');
        print('DEBUG: User data name field: ${data?['name']}');
        print('DEBUG: User data displayName field: ${data?['displayName']}');
        print('DEBUG: User data profilePhotoUrl field: ${data?['profilePhotoUrl']}');
        if (data != null) {
          // Database schema uses 'name' for user name
          final fetchedName = data['name'] as String?;
          // Try multiple possible avatar fields
          final fetchedAvatar = (data['profilePhotoUrl'] as String?);
          
          print('DEBUG: fetchedName=$fetchedName, fetchedAvatar=$fetchedAvatar');
          
          setState(() {
            if (fetchedName != null && fetchedName.isNotEmpty) {
              _actualPartnerName = fetchedName;
            }
            if (fetchedAvatar != null && fetchedAvatar.isNotEmpty) {
              _actualPartnerAvatarUrl = fetchedAvatar;
            }
          });
          print('DEBUG: Final _actualPartnerName=$_actualPartnerName, _actualPartnerAvatarUrl=$_actualPartnerAvatarUrl');
        }
      }
    } catch(e) {
      print('Error fetching partner profile: $e');
    }
  }



  Future<void> _checkExistingRoom() async {
    final existingRoomId = await _chatRepository.findRoom(widget.partnerId, widget.itemId);
    if (mounted && existingRoomId != null) {
      setState(() {
        _roomId = existingRoomId;
      });
      _chatRepository.markMessagesAsRead(existingRoomId);
    }
  }

  Future<void> _sendMessage() async {
    final String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      _messageController.clear();
      
      final roomId = await _chatRepository.sendMessage(
        existingRoomId: _roomId,
        partnerId: widget.partnerId,
        partnerName: _actualPartnerName ?? widget.partnerName,
        partnerAvatarUrl: _actualPartnerAvatarUrl ?? widget.partnerAvatarUrl,
        itemId: widget.itemId,
        itemName: widget.itemName,
        itemPhotoUrl: widget.itemPhotoUrl,
        messageText: text,
      );

      if (roomId != null && _roomId == null && mounted) {
        setState(() {
          _roomId = roomId;
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

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (pickedFile != null && mounted) {
      setState(() {
        _isUploadingImage = true;
      });

      final folderId = _roomId ?? '${_currentUserId}_${widget.partnerId}';
      final downloadUrl = await _chatRepository.uploadImage(File(pickedFile.path), folderId);
      
      if (downloadUrl != null && mounted) {
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

        if (newRoomId != null && _roomId == null && mounted) {
          setState(() {
            _roomId = newRoomId;
          });
        }
      }

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
              backgroundColor: const Color(0xFFFDF9F4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Icon
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B5804).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.report_problem_rounded,
                          color: Color(0xFF7B5804),
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Title
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
                    
                    // Subtitle
                    const Text(
                      'Pilih alasan utama Anda melaporkan pengguna ini. Laporan Anda akan ditinjau oleh tim kami.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF717973),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Reasons List
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
                                  ? const Color(0xFF1B4332).withValues(alpha: 0.05) 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? const Color(0xFF1B4332) 
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
                                      color: isSelected ? const Color(0xFF1B4332) : const Color(0xFF414844),
                                    ),
                                  ),
                                ),
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF1B4332) : const Color(0xFFC1C8C2),
                                      width: 2,
                                    ),
                                    color: isSelected ? const Color(0xFF1B4332) : Colors.transparent,
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
                    
                    // Action Buttons
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
                                color: Color(0xFF717973),
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
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengguna berhasil dilaporkan'),
                                    backgroundColor: Color(0xFF1B4332),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1B4332),
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

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Color_Background: #FDF9F4

      // --- SECTION 1: APPBAR / HEADER ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4), // ID: '195:1100'
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 16,
        title: Row(
          children: [
            // Back Button
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: const Icon(
                Icons.arrow_back_rounded, // ID: '196:1568'
                color: Color(0xFF012D1D), // Color_Primary_Dark
                size: 26,
              ),
            ),
            const SizedBox(width: 12),

            // Profile Info (Row)
            // Avatar
            ClipRRect(
              borderRadius: BorderRadius.circular(5), // ID: '214:2018'
              child: _actualPartnerAvatarUrl != null && _actualPartnerAvatarUrl!.isNotEmpty
                  ? Image(
                      image: _imageUploadService.buildImageProvider(_actualPartnerAvatarUrl!),
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      'assets/images/profile_user.png',
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                    ),
            ),
            const SizedBox(width: 12),

            // Name & Status Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _actualPartnerName ?? widget.partnerName, // ID: '196:1571'
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w500, // Poppins Medium
                      color: Color(0xFF414844),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Green Dot
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34DD48), // Color_Online_Dot: #34DD48
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        "Online",
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFF414844),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Right Action: More Options
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.black,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Laporkan Pengguna'),
                ),
              ],
            ),
          ],
        ),
      ),

      // --- MAIN BODY: COLUMN STRUCTURE ---
      body: Column(
        children: [
          // ### [SECTION 2: PINNED ITEM SUMMARY CARD] ###
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(itemId: widget.itemId),
                ),
              );
            },
            child: _buildPinnedItemCard(),
          ),
          
          const SizedBox(height: 8),

          // ### [SECTION 3: CHAT LIST (SCROLLABLE BUBBLES)] ###
          Expanded(
            child: _roomId == null
                ? const Center(
                    child: Text(
                      "Kirim pesan pertama Anda!",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.grey,
                      ),
                    ),
                  )
                : StreamBuilder<List<ChatMessageModel>>(
                    stream: _chatRepository.watchMessages(_roomId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF012D1D)));
                      }
                      
                      final messages = snapshot.data ?? [];
                      
                      // Auto-scroll to bottom when new messages arrive
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                        }
                      });

                      return ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          return _buildBubbleRow(messages[index]);
                        },
                      );
                    },
                  ),
          ),

          // ### [SECTION 4: BOTTOM CHAT INPUT (FIXED)] ###
          _buildBottomChatInput(),
        ],
      ),
    );
  }

  // Widget for Section 2: Pinned Item Summary Card
  Widget _buildPinnedItemCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, // ID: '209:1811' Background: #FFFFFF
        borderRadius: BorderRadius.circular(15), // BorderRadius: 15px
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.6), // Outline: #000000 1px (with subtle opacity)
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: widget.itemPhotoUrl.isNotEmpty
                ? Image(
                    image: _imageUploadService.buildImageProvider(widget.itemPhotoUrl),
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    'assets/images/sony_camera.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
          ),
          const SizedBox(width: 16),
          
          // Title & Price
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.itemName, // ID: '209:1819'
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w500, // Poppins Medium
                    color: Color(0xFF012D1D), // Color_Primary_Dark
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Rp. 15.000,00/jam", // ID: '214:1960'
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w500, // Poppins Medium
                    color: Color(0xFF7B5804), // Color_Accent: #7B5804
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget for generating single row with Bubble and Timestamp
  Widget _buildBubbleRow(ChatMessageModel message) {
    final bool isMe = message.senderId == _currentUserId;
    
    String timeString = "";
    if (message.sentAt != null) {
      timeString = DateFormat('HH:mm').format(message.sentAt!);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Message Bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe 
                  ? const Color(0xFF1B4332) // Color_Primary: #1B4332
                  : const Color(0xFFD9D9D9), // Color_Sender_Bubble: #D9D9D9
              borderRadius: isMe
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.zero, // Corner rule 4: Me (kanan)
                    )
                  : const BorderRadius.only(
                      topLeft: Radius.zero, // Corner rule 4: Sender (kiri)
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
            ),
            child: message.messageType == 'image'
                ? GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FullScreenImageViewer(imageUrl: message.message),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message.message,
                        width: 200,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : Text(
                    message.message,
                    style: TextStyle(
                      fontFamily: isMe ? 'Poppins' : 'Inter', // Font rules
                      fontSize: 12,
                      fontWeight: isMe ? FontWeight.w300 : FontWeight.w400, // Light vs Regular
                      color: isMe ? Colors.white : Colors.black,
                      height: 1.4,
                    ),
                  ),
          ),
          
          const SizedBox(height: 6),

          // Timestamp Row
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                timeString,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.w300, // Poppins Light
                  color: Color(0xFF414844),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.done_all_rounded,
                  size: 14,
                  color: message.isRead ? const Color(0xFF34DD48) : Colors.grey,
                ),
              ]
            ],
          ),
        ],
      ),
    );
  }

  // Widget for Section 4: Bottom Chat Input (Fixed)
  Widget _buildBottomChatInput() {
    return Container(
      // ID: '224:1398' -> Outer Background
      decoration: const BoxDecoration(
        color: Color(0xFF1B4332), // Color_Primary
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: SafeArea(
        top: false, // Ensure safety under iPhone home indicators (Layout rule 3)
        child: Row(
          children: [
            // Action 1: Plus Icon Circle Button
            GestureDetector(
              onTap: _pickAndSendImage,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF9F4), // Inverted Background Circle to pop
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.add, // Action 1 ID: '224:1410' Plus Icon
                    color: Color(0xFF1B4332), // Icon Color: #1B4332
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Inner Input Container (ID: '224:1399')
            Expanded(
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white, // Background: #FFFFFF
                  borderRadius: BorderRadius.circular(30), // BorderRadius: 30px
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                alignment: Alignment.center,
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    fontWeight: FontWeight.w500, // Medium
                    color: Color(0xFF012D1D), // Text: #012D1D
                  ),
                  onSubmitted: (_) => _sendMessage(),
                  decoration: const InputDecoration(
                    hintText: "Message....", // Hint Text (ID '224:1417')
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w500, // Poppins Medium
                      color: Color(0xFF9EAD9F), // Light muted hint color
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Action 2: Send Icon Circle Button
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDF9F4), // Matches Plus button for elegance
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded, // Action 2 ID '417:2181'
                    color: Color(0xFF1B4332), // Color: #1B4332
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                backgroundColor: const Color(0xFF1B4332),
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
