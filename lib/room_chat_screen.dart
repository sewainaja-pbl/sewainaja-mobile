import 'package:flutter/material.dart';

class RoomChatMessage {
  final String text;
  final String time;
  final bool isMe;

  RoomChatMessage({
    required this.text,
    required this.time,
    required this.isMe,
  });
}

class RoomChatScreen extends StatefulWidget {
  final String chatPartnerName;
  const RoomChatScreen({
    super.key, 
    this.chatPartnerName = "Han So Hee",
  });

  @override
  State<RoomChatScreen> createState() => _RoomChatScreenState();
}

class _RoomChatScreenState extends State<RoomChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Mock message data matching the flow
  final List<RoomChatMessage> _messages = [
    RoomChatMessage(
      text: "Halo kak, Sony A6000 nya masih ready?",
      time: "08:30",
      isMe: false,
    ),
    RoomChatMessage(
      text: "Halo! Iya kak, barangnya masih tersedia untuk disewa.",
      time: "08:32",
      isMe: true,
    ),
    RoomChatMessage(
      text: "Wah oke deh. Untuk kelengkapannya dapat apa aja ya?",
      time: "08:35",
      isMe: false,
    ),
    RoomChatMessage(
      text: "Dapat bodi kamera, lensa kit 16-50mm, 1 baterai, strap, dan tas kameranya kak.",
      time: "08:37",
      isMe: true,
    ),
    RoomChatMessage(
      text: "Apakah ini bisa disewa harian atau minimal mingguan ya kak?",
      time: "08:40",
      isMe: false,
    ),
    RoomChatMessage(
      text: "Bisa harian kak, tarifnya tercantum Rp 15.000/jam.",
      time: "08:42",
      isMe: true,
    ),
  ];

  void _sendMessage() {
    final String text = _messageController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add(
          RoomChatMessage(
            text: text,
            time: "08:45", // Static for prototype demo
            isMe: true,
          ),
        );
        _messageController.clear();
      });
      // Scroll to the bottom after sending
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
              child: Image.asset(
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
                    widget.chatPartnerName, // ID: '196:1571'
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
            IconButton(
              onPressed: () {},
              icon: const Icon(
                Icons.more_vert_rounded, // ID: '196:1639' -> bi:three-dots-vertical
                color: Colors.black,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),

      // --- MAIN BODY: COLUMN STRUCTURE ---
      body: Column(
        children: [
          // ### [SECTION 2: PINNED ITEM SUMMARY CARD] ###
          _buildPinnedItemCard(),
          
          const SizedBox(height: 8),

          // ### [SECTION 3: CHAT LIST (SCROLLABLE BUBBLES)] ###
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildBubbleRow(_messages[index]);
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
            borderRadius: BorderRadius.circular(12), // ID: '209:1816'
            child: Image.asset(
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
              children: const [
                Text(
                  "Sony a6000", // ID: '209:1819'
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
  Widget _buildBubbleRow(RoomChatMessage message) {
    final bool isMe = message.isMe;

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
            child: Text(
              message.text,
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
          Text(
            message.time,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 10,
              fontWeight: FontWeight.w300, // Poppins Light
              color: Color(0xFF414844),
            ),
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
              onTap: () {
                // Future functionality (attach image/file)
              },
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
