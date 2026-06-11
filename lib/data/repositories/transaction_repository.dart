import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../api_config.dart';
import '../../auth_session_service.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  final AuthSessionService _authService = const AuthSessionService();

  Future<List<TransactionModel>> fetchTransactions() async {
    final token = await _authService.getValidIdToken();
    if (token == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/transactions'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        final List<dynamic> data = body['data'] ?? [];
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      } else {
        throw Exception(body['error']?['message'] ?? 'Gagal mengambil data transaksi.');
      }
    } else {
      throw Exception('Gagal menghubungi server. (Kode: ${response.statusCode})');
    }
  }

  Future<TransactionModel> fetchTransactionById(String id) async {
    final token = await _authService.getValidIdToken();
    if (token == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/transactions/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return TransactionModel.fromJson(body['data']);
      } else {
        throw Exception(body['error']?['message'] ?? 'Gagal mengambil detail transaksi.');
      }
    } else {
      throw Exception('Gagal menghubungi server. (Kode: ${response.statusCode})');
    }
  }

  Future<void> requestAdendum(String id, DateTime newEndDate, double additionalCost, String paymentMethod) async {
    final token = await _authService.getValidIdToken();
    if (token == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/transactions/$id/extend'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'newEndDate': newEndDate.toIso8601String(),
        'additionalCost': additionalCost,
        'paymentMethod': paymentMethod,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] != true) {
        throw Exception(body['error']?['message'] ?? 'Gagal mengajukan perpanjangan.');
      }
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error']?['message'] ?? 'Gagal menghubungi server. (Kode: ${response.statusCode})');
    }
  }

  Future<void> approveAdendum(String id) async {
    final token = await _authService.getValidIdToken();
    if (token == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/transactions/$id/extend/approve'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] != true) {
        throw Exception(body['error']?['message'] ?? 'Gagal menyetujui perpanjangan.');
      }
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error']?['message'] ?? 'Gagal menghubungi server. (Kode: ${response.statusCode})');
    }
  }

  Future<void> rejectAdendum(String id) async {
    final token = await _authService.getValidIdToken();
    if (token == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/transactions/$id/extend/reject'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] != true) {
        throw Exception(body['error']?['message'] ?? 'Gagal menolak perpanjangan.');
      }
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error']?['message'] ?? 'Gagal menghubungi server. (Kode: ${response.statusCode})');
    }
  }

  Future<String> initiateAdendumPayment(String id) async {
    final token = await _authService.getValidIdToken();
    if (token == null) {
      throw Exception('Sesi telah habis, silakan login kembali.');
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/payments/initiate-adendum'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'transactionId': id,
      }),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        return body['data']['redirect_url']?.toString() ?? '';
      } else {
        throw Exception(body['error']?['message'] ?? 'Gagal memulai pembayaran.');
      }
    } else {
      final body = jsonDecode(response.body);
      throw Exception(body['error']?['message'] ?? 'Gagal menghubungi server. (Kode: ${response.statusCode})');
    }
  }
}
