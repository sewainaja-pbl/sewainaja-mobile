import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'room_chat_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'data/models/chat_model.dart';
import 'data/repositories/chat_repository.dart';
import 'image_upload_service.dart';

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ChatScreen({super.key, this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String selectedTab = "All"; // Tab Options: "All", "Unread", "Request"
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  void _handleBack() {
    final didPop = Navigator.of(context).maybePop();
    didPop.then((popped) {
      if (!popped && widget.onBack != null) {
        widget.onBack!();
      }
    });
  }

  final ChatRepository _chatRepository = ChatRepository();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  final ImageUploadService _imageUploadService = ImageUploadService();

  // Cache for unread counts per room (updated in real-time via stream)
  final Map<String, int> _unreadCounts = {};
  // Stream subscriptions for real-time unread count per room
  final Map<String, StreamSubscription<int>> _unreadSubscriptions = {};
  // Cache for actual partner profiles fetched from Firestore users collection
  final Map<String, Map<String, String?>> _partnerProfiles = {};

  /// Subscribe to real-time unread count for a room if not already subscribed.
  void _subscribeUnreadCount(String roomId) {
    if (_unreadSubscriptions.containsKey(roomId)) return;
    final sub = _chatRepository.watchUnreadCount(roomId).listen((newCount) {
      if (mounted) {
        setState(() {
          _unreadCounts[roomId] = newCount;
        });
      }
    });
    _unreadSubscriptions[roomId] = sub;
  }

  Future<void> _fetchPartnerProfile(String partnerId) async {
    if (_partnerProfiles.containsKey(partnerId)) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(partnerId).get();
      if (doc.exists && mounted) {
        final data = doc.data();
        if (data != null) {
          setState(() {
            _partnerProfiles[partnerId] = {
              'name': data['name'] as String? ?? '',
              'avatarUrl': data['profilePhotoUrl'] as String? ?? '',
            };
          });
        }
      }
    } catch (_) {}
  }

  List<ChatRoomModel> _filterChats(List<ChatRoomModel> chats) {
    List<ChatRoomModel> filtered = chats;

    // Apply tab filter
    if (selectedTab == "Unread") {
      filtered = filtered.where((room) {
        final count = _unreadCounts[room.id] ?? 0;
        return count > 0;
      }).toList();
    } else if (selectedTab == "Request") {
      // Request = rooms created by someone else (not the current user)
      // meaning someone initiated a chat with the current user
      filtered = filtered.where((room) {
        return room.createdBy != null && room.createdBy != _currentUserId;
      }).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((room) {
        // Search by partner name
        String partnerName = "";
        for (var entry in room.participants.entries) {
          if (entry.key != _currentUserId) {
            // Check cached profile first
            final cached = _partnerProfiles[entry.key];
            partnerName = (cached?['name']?.isNotEmpty == true)
                ? cached!['name']!
                : entry.value.name;
            break;
          }
        }
        // Search by item name or partner name
        return partnerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            room.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _searchController.dispose();
    // Cancel all real-time unread subscriptions
    for (final sub in _unreadSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFFDF9F4,
      ), // Background Color ID: '217:2058'
      // --- SECTION 1: APPBAR ---
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF9F4),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        titleSpacing: 24,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(
            children: [
              // Back Button
              GestureDetector(
                onTap: _handleBack,
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF012D1D), // ID: '635:1593' Color
                  size: 28,
                ),
              ),
              const Spacer(),
              // Title "Chat"
              const Text(
                "Chat",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w600, // SemiBold
                  color: Color(0xFF012D1D), // ID: '217:2059' Color
                ),
              ),
              const Spacer(),
              // Dummy spacing to balance the centered title
              const SizedBox(width: 28),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF012D1D).withValues(alpha: 0),
                  const Color(0xFF012D1D).withValues(alpha: 0.28),
                  const Color(0xFF012D1D).withValues(alpha: 0),
                ],
                stops: const [0, 0.5, 1],
              ),
            ),
          ),
        ),
      ),

      // --- MAIN COLUMN CONTENT ---
      body: Column(
        children: [
          // Fixed Headers Area (Search & Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),

                // ### [SECTION 2: SEARCH BAR] ###
                _buildSearchBar(),
                const SizedBox(height: 16),

                // ### [SECTION 3: TAB FILTER BAR] ###
                _buildTabFilterBar(),
                const SizedBox(height: 24),
              ],
            ),
          ),

          Expanded(
            child: StreamBuilder<List<ChatRoomModel>>(
              stream: _chatRepository.watchMyChatRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF012D1D)));
                }

                final chats = snapshot.data ?? [];
                
                // Subscribe to real-time unread counts and fetch partner profiles
                for (final room in chats) {
                  _subscribeUnreadCount(room.id);
                  for (var entry in room.participants.entries) {
                    if (entry.key != _currentUserId) {
                      _fetchPartnerProfile(entry.key);
                    }
                  }
                }

                final filteredChats = _filterChats(chats);

                if (filteredChats.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: 110,
                  ),
                  itemCount: filteredChats.length,
                  itemBuilder: (context, index) {
                    return _buildChatCard(filteredChats[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Empty States
  Widget _buildEmptyState() {
    String message;
    if (selectedTab == "Unread") {
      message = "Tidak ada pesan yang belum dibaca";
    } else if (selectedTab == "Request") {
      message = "Tidak ada permintaan chat baru";
    } else if (_searchQuery.isNotEmpty) {
      message = "Tidak ditemukan hasil untuk \"$_searchQuery\"";
    } else {
      message = "Belum ada percakapan";
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            selectedTab == "Request"
                ? Icons.person_add_disabled_rounded
                : Icons.chat_bubble_outline_rounded,
            size: 64,
            color: const Color(0xFF919191).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Color(0xFF414844),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for Section 2: Search Bar
  Widget _buildSearchBar() {
    return Container(
      height: 50, // Spec Height 50
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // BorderRadius: 12
        border: Border.all(
          color: const Color(0xFF919191), // Stroke: #919191 1px
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.trim();
          });
        },
        style: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: "Search . . .", // Placeholder
          hintStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w300, // Light
            color: Colors.black, // Spec Placeholder color
          ),
          prefixIcon: const Icon(
            Icons.search_rounded, // Leading Icon
            color: Colors.black,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF919191)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  // Widget for Section 3: Tab Filter Bar
  Widget _buildTabFilterBar() {
    return Row(
      children: [
        Expanded(child: _buildTabItem("All")),
        const SizedBox(width: 12),
        Expanded(child: _buildTabItem("Unread")),
        const SizedBox(width: 12),
        Expanded(child: _buildTabItem("Request")),
      ],
    );
  }

  // Helper Tab Item Widget
  Widget _buildTabItem(String label) {
    final bool isActive = selectedTab == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = label;
        });
      },
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF012D1D)
              : Colors.white, // Background active/inactive
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF919191), // Border #919191 1px
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive
                ? Colors.white
                : const Color(0xFF414844), // Text active/inactive
          ),
        ),
      ),
    );
  }

  // Widget for Chat Cards inside ListView
  Widget _buildChatCard(ChatRoomModel room) {
    // Find partner info
    String partnerId = "";
    ChatParticipantInfo? partnerInfo;
    for (var entry in room.participants.entries) {
      if (entry.key != _currentUserId) {
        partnerId = entry.key;
        partnerInfo = entry.value;
        break;
      }
    }

    // Use cached Firestore profile if available, fallback to denormalized data
    final cachedProfile = _partnerProfiles[partnerId];
    final String partnerName = (cachedProfile?['name']?.isNotEmpty == true)
        ? cachedProfile!['name']!
        : (partnerInfo?.name ?? "Unknown");
    final String partnerAvatarUrl = (cachedProfile?['avatarUrl']?.isNotEmpty == true)
        ? cachedProfile!['avatarUrl']!
        : (partnerInfo?.avatarUrl ?? "");
    final String lastMessage = room.lastMessage;
    final int unreadCount = _unreadCounts[room.id] ?? 0;
    final bool hasUnread = unreadCount > 0;

    // Format time
    String timeString = "";
    if (room.lastMessageAt != null) {
      final now = DateTime.now();
      final diff = now.difference(room.lastMessageAt!);
      if (diff.inDays == 0) {
        timeString = DateFormat('HH:mm').format(room.lastMessageAt!);
      } else if (diff.inDays == 1) {
        timeString = "Kemarin";
      } else if (diff.inDays < 7) {
        timeString = DateFormat('EEEE').format(room.lastMessageAt!);
      } else {
        timeString = DateFormat('dd/MM/yy').format(room.lastMessageAt!);
      }
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomChatScreen(
              initialRoomId: room.id,
              partnerId: partnerId,
              partnerName: partnerName,
              partnerAvatarUrl: partnerAvatarUrl,
              itemId: room.itemId,
              itemName: room.itemName,
              itemPhotoUrl: room.itemPhotoUrl,
            ),
          ),
        );
        // Stream subscription automatically updates unread count in real-time.
        // No manual refresh needed here.
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white, // ID: '217:2070' Background: #FFFFFF
          borderRadius: BorderRadius.circular(12), // BorderRadius: 12
          border: Border.all(
            color: const Color(
              0xFF919191,
            ).withValues(alpha: 0.8), // Border: #919191
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // --- UPPER CARD (USER INFO) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar Rectangle (Radius 5px)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: partnerAvatarUrl.isNotEmpty
                        ? Image(
                            image: _imageUploadService.buildImageProvider(partnerAvatarUrl),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset(
                                'assets/images/profile_user.png',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              );
                            },
                          )
                        : Image.asset(
                            'assets/images/profile_user.png',
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),

                  // Text Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          partnerName, // ID: '217:2071'
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.lastMessage.startsWith('https://') ? '📷 Foto' : lastMessage, // ID: '217:2072'
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w300,
                            color: hasUnread ? Colors.black : const Color(0xFF585D59),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time & Unread Badge Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeString,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          fontWeight: FontWeight.w400,
                          color: hasUnread ? const Color(0xFF012D1D) : const Color(0xFF919191),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF012D1D),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),

              // --- DIVIDER ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  height: 1,
                  color: const Color(
                    0xFF919191,
                  ).withValues(alpha: 0.6), // ID: '217:2073' Divider
                ),
              ),

              // --- LOWER CARD (PRODUCT INFO) ---
              Row(
                children: [
                  // Product Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: room.itemPhotoUrl.isNotEmpty
                        ? Image(
                            image: _imageUploadService.buildImageProvider(room.itemPhotoUrl),
                            width: 26,
                            height: 26,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 26,
                                height: 26,
                                color: const Color(0xFFF5F5F5),
                                child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFFB0B0B0), size: 16),
                              );
                            },
                          )
                        : Container(
                            width: 26,
                            height: 26,
                            color: const Color(0xFFF5F5F5),
                            child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFFB0B0B0), size: 16),
                          ),
                  ),
                  const SizedBox(width: 10),

                  // Product Name
                  Expanded(
                    child: Text(
                      room.itemName, // ID: '217:2076'
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.w300, // Light
                        color: Colors.black,
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
}
