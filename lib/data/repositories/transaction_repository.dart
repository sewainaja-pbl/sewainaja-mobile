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
}
