import 'package:flutter/material.dart';
import 'room_chat_screen.dart';

class ChatMessage {
  final String userName;
  final String messagePreview;
  final String userAvatar;
  final String productName;
  final String productThumbnail;
  final bool isUnread;
  final bool isRequest;

  ChatMessage({
    required this.userName,
    required this.messagePreview,
    required this.userAvatar,
    required this.productName,
    required this.productThumbnail,
    this.isUnread = false,
    this.isRequest = false,
  });
}

class ChatScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const ChatScreen({super.key, this.onBack});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  String selectedTab = "All"; // Tab Options: "All", "Unread", "Request"

  // Mock Data matching the provided images
  final List<ChatMessage> _allChats = [
    ChatMessage(
      userName: "JoyKowi",
      messagePreview: "Apakah ini masih ada?",
      userAvatar: "assets/images/profile_user.png",
      productName: "Sony A6000",
      productThumbnail: "assets/images/sony_camera.png",
      isUnread: true,
      isRequest: true,
    ),
    ChatMessage(
      userName: "JoyKowi",
      messagePreview: "Apakah ini masih ada?",
      userAvatar: "assets/images/profile_user.png",
      productName: "Sony A6000",
      productThumbnail: "assets/images/sony_camera.png",
      isUnread: true,
      isRequest: true,
    ),
    ChatMessage(
      userName: "JoyKowi",
      messagePreview: "Apakah ini masih ada?",
      userAvatar: "assets/images/profile_user.png",
      productName: "Sony A6000",
      productThumbnail: "assets/images/sony_camera.png",
      isUnread: false,
      isRequest: true,
    ),
    ChatMessage(
      userName: "JoyKowi",
      messagePreview: "Apakah ini masih ada?",
      userAvatar: "assets/images/profile_user.png",
      productName: "Sony A6000",
      productThumbnail: "assets/images/sony_camera.png",
      isUnread: true,
      isRequest: false,
    ),
    ChatMessage(
      userName: "JoyKowi",
      messagePreview: "Apakah ini masih ada?",
      userAvatar: "assets/images/profile_user.png",
      productName: "Sony A6000",
      productThumbnail: "assets/images/sony_camera.png",
      isUnread: false,
      isRequest: false,
    ),
    ChatMessage(
      userName: "JoyKowi",
      messagePreview: "Apakah ini masih ada?",
      userAvatar: "assets/images/profile_user.png",
      productName: "Sony A6000",
      productThumbnail: "assets/images/sony_camera.png",
      isUnread: false,
      isRequest: true,
    ),
  ];

  // List filtering logic
  List<ChatMessage> get _filteredChats {
    if (selectedTab == "Unread") {
      return _allChats.where((chat) => chat.isUnread).toList();
    } else if (selectedTab == "Request") {
      return _allChats.where((chat) => chat.isRequest).toList();
    }
    return _allChats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Background Color ID: '217:2058'
      
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
                onTap: () {
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else {
                    Navigator.maybePop(context);
                  }
                },
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

          // ### [SECTION 4: CHAT LIST VIEW] ###
          Expanded(
            child: _filteredChats.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 110), // Navbar Whitespace Fix
                    itemCount: _filteredChats.length,
                    itemBuilder: (context, index) {
                      return _buildChatCard(_filteredChats[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget for Empty States
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 64,
            color: const Color(0xFF919191).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "Tidak ada pesan di tab $selectedTab",
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
      child: const TextField(
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: Colors.black,
        ),
        decoration: InputDecoration(
          hintText: "Search . . .", // Placeholder
          hintStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            fontWeight: FontWeight.w300, // Light
            color: Colors.black, // Spec Placeholder color
          ),
          prefixIcon: Icon(
            Icons.search_rounded, // Leading Icon
            color: Colors.black,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
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
          color: isActive ? const Color(0xFF012D1D) : Colors.white, // Background active/inactive
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
            color: isActive ? Colors.white : const Color(0xFF414844), // Text active/inactive
          ),
        ),
      ),
    );
  }

  // Widget for Chat Cards inside ListView
  Widget _buildChatCard(ChatMessage chat) {
    // Determine whether to show exclamation icon based on design rules
    // "Ikon amplop merah hanya muncul pada mode tab Request"
    final bool showRedIcon = (selectedTab == "Request") && chat.isRequest;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomChatScreen(chatPartnerName: chat.userName),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white, // ID: '217:2070' Background: #FFFFFF
          borderRadius: BorderRadius.circular(12), // BorderRadius: 12
          border: Border.all(
            color: const Color(0xFF919191).withValues(alpha: 0.8), // Border: #919191
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
                    borderRadius: BorderRadius.circular(5), // ID: '217:2077'
                    child: Image.asset(
                      chat.userAvatar,
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
                          chat.userName, // ID: '217:2071'
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            fontWeight: FontWeight.w600, // SemiBold
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chat.messagePreview, // ID: '217:2072'
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            fontWeight: FontWeight.w300, // Light
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
  
                  // Trailing red warning envelope (Conditional UI)
                  if (showRedIcon) _buildRedExclamationEnvelope(),
                ],
              ),
  
              // --- DIVIDER ---
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Container(
                  height: 1,
                  color: const Color(0xFF919191).withValues(alpha: 0.6), // ID: '217:2073' Divider
                ),
              ),
  
              // --- LOWER CARD (PRODUCT INFO) ---
              Row(
                children: [
                  // Product Image Thumbnail
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.asset(
                      chat.productThumbnail, // ID: '217:2075'
                      width: 26,
                      height: 26,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Product Name
                  Expanded(
                    child: Text(
                      chat.productName, // ID: '217:2076'
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

  // Polished Red Exclamation Envelope widget
  Widget _buildRedExclamationEnvelope() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Envelope
        const Icon(
          Icons.mail_outline_rounded,
          color: Color(0xFFFF0000), // Color_Alert: #FF0000
          size: 26,
        ),
        // Exclamation Point Overlay
        Positioned(
          right: -4,
          bottom: -3,
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.error_rounded, // Material Exclamation Symbol
              color: Color(0xFFFF0000),
              size: 12,
            ),
          ),
        ),
      ],
    );
  }
}
