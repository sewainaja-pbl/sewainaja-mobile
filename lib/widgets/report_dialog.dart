import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_feedback.dart';

/// Menampilkan dialog pelaporan barang terpadu dan menyimpannya ke Firestore.
void showReportDialog(
  BuildContext context, {
  required String reportedId,
  required String itemId,
  required String itemName,
}) {
  showDialog(
    context: context,
    barrierDismissible: false, // Mencegah tutup dialog saat loading
    builder: (context) => _ReportDialogContent(
      reportedId: reportedId,
      itemId: itemId,
      itemName: itemName,
    ),
  );
}

class _ReportDialogContent extends StatefulWidget {
  final String reportedId;
  final String itemId;
  final String itemName;

  const _ReportDialogContent({
    required this.reportedId,
    required this.itemId,
    required this.itemName,
  });

  @override
  State<_ReportDialogContent> createState() => _ReportDialogContentState();
}

class _ReportDialogContentState extends State<_ReportDialogContent> {
  final TextEditingController _reasonController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = 'bad_item'; // default type
  bool _isLoading = false;

  final Map<String, String> _reportTypes = {
    'bad_item': 'Barang Tidak Sesuai / Rusak',
    'fraud': 'Penipuan',
    'harassment': 'Pelecehan / Perilaku Buruk',
    'other': 'Lainnya',
  };

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pop(context);
          showAppErrorSnack(context, 'Anda harus login untuk melaporkan barang.');
        }
        return;
      }

      final reportData = {
        'reporterId': user.uid,
        'reportedId': widget.reportedId,
        'itemId': widget.itemId,
        'itemName': widget.itemName,
        'type': _selectedType,
        'reason': _reasonController.text.trim(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('user_reports').add(reportData);

      if (mounted) {
        Navigator.pop(context); // Tutup dialog
        showAppSuccessSnack(
          context,
          'Laporan Anda telah terkirim. Terima kasih atas masukan Anda!',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        showAppErrorSnack(context, 'Gagal mengirim laporan. Silakan coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFFFF8EF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Laporkan Barang',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Color(0xFF012D1D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.itemName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF585D59),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Laporkan barang ini jika melanggar ketentuan layanan kami, merupakan penipuan, atau rusak.',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF414844)),
              ),
              const SizedBox(height: 16),
              
              // Dropdown Tipe Laporan
              const Text(
                'Kategori Laporan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF012D1D),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                ),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF012D1D)),
                items: _reportTypes.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(entry.value),
                  );
                }).toList(),
                onChanged: _isLoading
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedType = val;
                          });
                        }
                      },
              ),
              const SizedBox(height: 16),
              
              // Input Alasan
              const Text(
                'Detail Alasan',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF012D1D),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 4,
                enabled: !_isLoading,
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Tulis alasan laporan Anda secara jelas di sini...',
                  hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF8E9591)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Alasan tidak boleh kosong';
                  }
                  if (value.trim().length < 5) {
                    return 'Berikan alasan yang lebih detail (min. 5 karakter)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text(
            'Batal',
            style: TextStyle(fontFamily: 'Poppins', color: Color(0xFF585D59), fontWeight: FontWeight.w600),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE33629),
            disabledBackgroundColor: const Color(0xFFE33629).withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: _isLoading ? null : _submitReport,
          child: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Kirim',
                  style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontWeight: FontWeight.bold),
                ),
        ),
      ],
    );
  }
}
