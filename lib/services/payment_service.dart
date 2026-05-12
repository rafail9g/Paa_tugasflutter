import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paa_gacor/config/api_config.dart';
import 'package:paa_gacor/models/payment.dart';
import 'package:paa_gacor/services/auth_service.dart';

class PaymentService {
  static const String _prefix = '/api/payments';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ── Buat pembayaran baru ─────────────────────────────────────────────────
  // API hanya terima JSON (tidak ada upload file)
  // method: 'transfer_bank' | 'cash' | 'card'
  static Future<PaymentModel> createPayment({
    required String bookingId,
    required double amount,
    required String method,
    String? bankName,
    String? accountNumber,
    String? accountName,
    String? transactionId,
    String? notes,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      'bookingId': bookingId,
      'method': method,
      if (bankName != null && bankName.isNotEmpty) 'bankName': bankName,
      if (accountNumber != null && accountNumber.isNotEmpty)
        'accountNumber': accountNumber,
      if (accountName != null && accountName.isNotEmpty)
        'accountName': accountName,
      if (transactionId != null && transactionId.isNotEmpty)
        'transactionId': transactionId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response =
        await http.post(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = responseBody['data'];
      return PaymentModel.fromJson(data['payment'] ?? data);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal membuat pembayaran');
    }
  }

  // ── Ambil detail pembayaran by ID ────────────────────────────────────────
  static Future<PaymentModel> getPaymentById(String paymentId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$paymentId');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);
    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = body['data'];
      return PaymentModel.fromJson(data['payment'] ?? data);
    } else {
      throw Exception(body['message'] ?? 'Gagal memuat pembayaran');
    }
  }

  // ── Ambil riwayat pembayaran user ────────────────────────────────────────
  static Future<List<PaymentModel>> getMyPayments({
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix')
        .replace(queryParameters: queryParams);
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);
    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = body['data'];
      final list = data['payments'] as List? ?? [];
      return list.map((e) => PaymentModel.fromJson(e)).toList();
    } else {
      throw Exception(body['message'] ?? 'Gagal memuat riwayat pembayaran');
    }
  }

  // ── Admin: verifikasi / tolak pembayaran ─────────────────────────────────
  // status: 'success' | 'failed'
  static Future<PaymentModel> verifyPayment(
    String paymentId, {
    required bool isVerified,
    String? notes,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}$_prefix/$paymentId/verify');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      'status': isVerified ? 'success' : 'failed',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response =
        await http.put(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = responseBody['data'];
      return PaymentModel.fromJson(data['payment'] ?? data);
    } else {
      throw Exception(
          responseBody['message'] ?? 'Gagal memverifikasi pembayaran');
    }
  }

  // ── Admin: refund pembayaran ──────────────────────────────────────────────
  static Future<void> refundPayment(
    String paymentId, {
    required double refundAmount,
    required String refundReason,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}$_prefix/$paymentId/refund');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      'refundAmount': refundAmount,
      'refundReason': refundReason,
    };

    final response =
        await http.put(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode != 200) {
      throw Exception(responseBody['message'] ?? 'Gagal memproses refund');
    }
  }
}