import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'data/models/transaction_model.dart';
import 'data/repositories/transaction_repository.dart';
import 'dispute_form_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  String? _selectedRole;
  final TransactionRepository _repository = TransactionRepository();
  List<TransactionModel> _transactions = [];
  bool _isLoading = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _repository.fetchTransactions();
      if (mounted) {
        setState(() {
          _transactions = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TransactionModel> get _recommendedTransactions {
    if (_selectedRole == null) return [];
    
    final currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return [];

    var filtered = _transactions.where((tx) {
      if (_selectedRole == 'pemilik') {
        return tx.ownerId == currentUserUid;
      } else if (_selectedRole == 'penyewa') {
        return tx.renterId == currentUserUid;
      }
      return false;
    }).toList();

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((tx) {
        final targetName = _selectedRole == 'pemilik' ? tx.renterName : tx.ownerName;
        return targetName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    final uniqueUsers = <String, TransactionModel>{};
    for (var tx in filtered) {
      final targetId = _selectedRole == 'pemilik' ? tx.renterId : tx.ownerId;
      if (!uniqueUsers.containsKey(targetId)) {
        uniqueUsers[targetId] = tx;
      }
    }
    return uniqueUsers.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8EF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF012D1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: Color(0xFF012D1D),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderAndSearch(),
            _buildSupportActionCards(),
            _buildHelpCategoriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAndSearch() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Halo, ada yang bisa kami\nbantu?',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 24,
              height: 1.3,
              color: Color(0xFF012D1D),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Pilih jenis bantuan atau laporkan kendala Anda.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF414844),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportActionCards() {
    final isPemilik = _selectedRole == 'pemilik';
    final isPenyewa = _selectedRole == 'penyewa';

    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
      child: Column(
        children: [
          // Card: Laporan Kendala
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF012D1D).withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDAD6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFF93000A),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Laporan Kendala',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pilih peran Anda untuk melaporkan masalah transaksi atau indikasi penipuan.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    height: 1.4,
                    color: Color(0xFF414844),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedRole = isPemilik ? null : 'pemilik';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isPemilik ? const Color(0xFF012D1D) : Colors.transparent,
                          side: const BorderSide(color: Color(0xFF012D1D), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: isPemilik ? Colors.white : const Color(0xFF012D1D),
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saya Pemilik',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isPemilik ? Colors.white : const Color(0xFF012D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _selectedRole = isPenyewa ? null : 'penyewa';
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: isPenyewa ? const Color(0xFF012D1D) : Colors.transparent,
                          side: const BorderSide(color: Color(0xFF012D1D), width: 1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: isPenyewa ? Colors.white : const Color(0xFF012D1D),
                              size: 18,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Saya Penyewa',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: isPenyewa ? Colors.white : const Color(0xFF012D1D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_selectedRole != null) ...[
            const SizedBox(height: 24),
            _buildSearchAndRecommendations(),
          ]
        ],
      ),
    );
  }

  Widget _buildSearchAndRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
          },
          decoration: InputDecoration(
            hintText: _selectedRole == 'pemilik' ? 'Cari nama penyewa...' : 'Cari nama pemilik...',
            hintStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: Color(0xFF717973),
            ),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF717973)),
            filled: true,
            fillColor: const Color(0xFFFFFFFF),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: const Color(0xFF012D1D).withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: BorderSide(
                color: const Color(0xFF012D1D).withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(999),
              borderSide: const BorderSide(
                color: Color(0xFF012D1D),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Rekomendasi Histori Transaksi',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: Color(0xFF012D1D),
          ),
        ),
        const SizedBox(height: 12),
        _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF012D1D)))
            : _buildRecommendationsList(),
      ],
    );
  }

  Widget _buildRecommendationsList() {
    final recommendations = _recommendedTransactions;
    if (recommendations.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFFFF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF012D1D).withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          _searchQuery.isEmpty 
              ? 'Tidak ada histori transaksi yang relevan.' 
              : 'Tidak ditemukan pengguna dengan nama "$_searchQuery".',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            color: Color(0xFF414844),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recommendations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final tx = recommendations[index];
        final targetName = _selectedRole == 'pemilik' ? tx.renterName : tx.ownerName;
        final targetInitials = targetName.isNotEmpty ? targetName[0].toUpperCase() : '?';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DisputeFormScreen(
                  transactionId: tx.id,
                  category: 'other',
                  itemName: tx.details.isNotEmpty ? tx.details.first.itemNameSnapshot : 'Laporan Transaksi',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF012D1D).withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFC1ECD4),
                  child: Text(
                    targetInitials,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF012D1D),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        targetName,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF012D1D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID Transaksi: ${tx.id.substring(0, 8)}...',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Color(0xFF717973),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Color(0xFF717973),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHelpCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Bantuan',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 16),
          _buildCategoryItem(
            icon: Icons.security_outlined,
            title: 'Akun & Keamanan',
            subtitle: 'Password, verifikasi, privasi',
          ),
          const SizedBox(height: 24),
          const Text(
            'Cantumkan Email Anda',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            decoration: InputDecoration(
              hintText: 'Contoh: nama@email.com',
              hintStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: Color(0xFF717973),
              ),
              filled: true,
              fillColor: const Color(0xFFFFFFFF),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF012D1D).withValues(alpha: 0.1),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: const Color(0xFF012D1D).withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF012D1D),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '*Nanti panduan lebih lanjut akan dikirimkan lewat email.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: Color(0xFF717973),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bantuan akan segera dikirimkan ke email Anda.')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF012D1D),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Kirim Permintaan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                );
              },
              child: const Text(
                'Lupa password akun? Atur ulang di sini.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7B5804),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF012D1D).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF012D1D),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF012D1D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF414844),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
