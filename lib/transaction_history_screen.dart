import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'main_navigation_screen.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/transaction_repository.dart';
import 'transaction_detail_screen.dart';
import 'widgets/custom_app_bar.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ["Penyewa", "Pemilik"];

  final TransactionRepository _repository = TransactionRepository();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repository.fetchTransactions();
      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }

      // Fetch details for each transaction asynchronously to get the item names and photos
      for (var tx in data) {
        if (tx.details.isEmpty) {
          _repository.fetchTransactionById(tx.id).then((fullTx) {
            if (mounted) {
              setState(() {
                final idx = _transactions.indexWhere((t) => t.id == tx.id);
                if (idx != -1) {
                  _transactions[idx] = fullTx;
                }
              });
            }
          }).catchError((_) {
            // Ignore error for individual transaction
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<TransactionModel> get _filteredTransactions {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (_selectedTabIndex == 0) {
      return _transactions.where((t) => t.renterId == currentUid).toList();
    } else if (_selectedTabIndex == 1) {
      return _transactions.where((t) => t.ownerId == currentUid).toList();
    }
    return _transactions;
  }

  String _getPartnerName(TransactionModel trans) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (trans.renterId == currentUid) {
      return 'Pemilik: ${trans.ownerName}';
    } else {
      return 'Penyewa: ${trans.renterName}';
    }
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status.toLowerCase()) {
      case 'pending':
        bgColor = const Color(0xFFFFF4DB);
        textColor = const Color(0xFFB8860B);
        label = 'Menunggu';
        break;
      case 'approved':
        bgColor = const Color(0xFFE8F0EB);
        textColor = const Color(0xFF2D5C44);
        label = 'Disetujui';
        break;
      case 'ongoing':
        bgColor = const Color(0xFFD0E1D4);
        textColor = const Color(0xFF1A3C2E);
        label = 'Berlangsung';
        break;
      case 'completed':
        bgColor = const Color(0xFFD1F2E5);
        textColor = const Color(0xFF10B981);
        label = 'Selesai';
        break;
      case 'cancelled':
        bgColor = const Color(0xFFFDE8E8);
        textColor = const Color(0xFFF04438);
        label = 'Batal';
        break;
      case 'disputed':
        bgColor = const Color(0xFFFFF4DB);
        textColor = const Color(0xFFF59E0B);
        label = 'Sengketa';
        break;
      case 'waiting_rating':
        bgColor = const Color(0xFFFFF4DB);
        textColor = const Color(0xFFB8860B);
        label = 'Rating';
        break;
      default:
        bgColor = const Color(0xFFEEEEEE);
        textColor = const Color(0xFF6B6B6B);
        label = status.toUpperCase();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF9F4), // Krem Terang
      appBar: const CustomAppBar(
        title: 'History',
      ),
      extendBody: true,
      body: Stack(
        children: [
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                int index = entry.key;
                String label = entry.value;
                bool isActive = index == _selectedTabIndex;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                color: isActive
                                    ? const Color(0xFF1B4332)
                                    : const Color(0xFF828282),
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (isActive)
                              Container(
                                height: 2,
                                color: const Color(0xFF1B4332),
                              )
                            else
                              const SizedBox(height: 2), // Hindari layout melompat
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 8),

          // ListView History
          Expanded(
            child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B4332)))
                : _errorMessage != null
                    ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                    : _filteredTransactions.isEmpty
                        ? const Center(
                            child: Text(
                              "Tidak ada riwayat transaksi.",
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: Color(0xFF414844),
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadTransactions,
                            color: const Color(0xFF1B4332),
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 120.0),
                              itemCount: _filteredTransactions.length,
                              itemBuilder: (context, index) {
                                final item = _filteredTransactions[index];
                                final detail = item.details.isNotEmpty ? item.details.first : null;
                                final String itemName = detail?.itemNameSnapshot ?? "Transaksi ${item.id.substring(0, 5)}";
                                final String itemImage = (detail != null && detail.itemPhotoUrlSnapshot.isNotEmpty) 
                                    ? detail.itemPhotoUrlSnapshot 
                                    : "";
                                
                                String dateRange = "";
                                if (detail != null && detail.startDate != null && detail.endDate != null) {
                                  dateRange = "${DateFormat('d MMM').format(detail.startDate!)} - ${DateFormat('d MMM yyyy').format(detail.endDate!)}";
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TransactionDetailScreen(transactionId: item.id),
                                        ),
                                      ).then((_) => _loadTransactions());
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(12.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFFFFF),
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.03),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        children: [
                                          // Image Thumbnail
                                          Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(15),
                                              color: Colors.grey.shade200,
                                              image: itemImage.isNotEmpty 
                                                ? DecorationImage(
                                                    image: NetworkImage(itemImage),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                            ),
                                            child: itemImage.isEmpty
                                                ? const Center(
                                                    child: Icon(
                                                      Icons.image_outlined,
                                                      color: Color(0xFF828282),
                                                      size: 32,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          
                                          // Details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        itemName,
                                                        style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600, // Semibold
                                                          color: Color(0xFF414844),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    _buildStatusBadge(item.status),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _getPartnerName(item),
                                                  style: const TextStyle(
                                                    fontFamily: 'Poppins',
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w400, // Regular
                                                    color: Color(0xFF414844),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_month_rounded,
                                                      size: 14,
                                                      color: Color(0xFF414844),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        dateRange,
                                                        style: const TextStyle(
                                                          fontFamily: 'Poppins',
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w400, // Regular
                                                          color: Color(0xFF414844),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
          _buildBottomNavigationBar(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          height: 75,
          margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF012D1D),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF012D1D).withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(index: 0, activeIcon: Icons.home_rounded, inactiveIcon: Icons.home_outlined),
              _buildNavItem(index: 1, activeIcon: Icons.grid_view_rounded, inactiveIcon: Icons.grid_view_outlined),
              _buildNavItem(index: 2, activeIcon: Icons.add_box_rounded, inactiveIcon: Icons.add_box_outlined),
              _buildNavItem(index: 3, activeIcon: Icons.chat_bubble_rounded, inactiveIcon: Icons.chat_bubble_outline_rounded),
              _buildNavItem(index: 4, activeIcon: Icons.person_rounded, inactiveIcon: Icons.person_outline_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required int index, required IconData activeIcon, required IconData inactiveIcon}) {
    final bool isActive = 4 == index; // Profile is always active

    return GestureDetector(
      onTap: () {
        if (index == 4) {
          Navigator.pop(context); // Go back to profile screen
        } else {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => MainNavigationScreen(initialIndex: index),
            ),
            (route) => false,
          );
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: 55,
        height: 55,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFF8EF) : const Color(0xFF1B4332),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: Icon(
              isActive ? activeIcon : inactiveIcon,
              key: ValueKey<bool>(isActive),
              color: isActive ? const Color(0xFF012D1D) : const Color(0xFFFFF8EF),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
