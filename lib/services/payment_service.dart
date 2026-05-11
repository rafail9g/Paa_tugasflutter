import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:paa_gacor/models/payment.dart';
import 'package:paa_gacor/services/auth_service.dart'; // sesuaikan path token

class PaymentService {
  static const _baseUrl =
      'https://your-api.com/api'; // ganti dengan base URL kamu

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Buat pembayaran baru. Jika ada proofImage, upload sebagai multipart.
  static Future<PaymentModel> createPayment({
    required String bookingId,
    required double amount,
    required String method,
    String? notes,
    File? proofImage,
  }) async {
    final token = await AuthService.getToken();
    final headers = {if (token != null) 'Authorization': 'Bearer $token'};

    if (proofImage != null) {
      // Multipart request untuk upload bukti transfer
      final request =
          http.MultipartRequest('POST', Uri.parse('$_baseUrl/payments'))
            ..headers.addAll(headers)
            ..fields['booking'] = bookingId
            ..fields['amount'] = amount.toString()
            ..fields['method'] = method;

      if (notes != null && notes.isNotEmpty) {
        request.fields['notes'] = notes;
      }

      request.files.add(
        await http.MultipartFile.fromPath('proof', proofImage.path),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return PaymentModel.fromJson(data['payment'] ?? data);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['message'] ?? 'Gagal membuat pembayaran');
      }
    } else {
      // JSON request untuk cash/card
      final response = await http.post(
        Uri.parse('$_baseUrl/payments'),
        headers: await _headers(),
        body: json.encode({
          'booking': bookingId,
          'amount': amount,
          'method': method,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return PaymentModel.fromJson(data['payment'] ?? data);
      } else {
        final err = json.decode(response.body);
        throw Exception(err['message'] ?? 'Gagal membuat pembayaran');
      }
    }
  }

  /// Ambil detail payment berdasarkan ID
  static Future<PaymentModel> getPaymentById(String paymentId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/$paymentId'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return PaymentModel.fromJson(data['payment'] ?? data);
    } else {
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Gagal memuat pembayaran');
    }
  }

  /// Ambil list payment milik user yang login
  static Future<List<PaymentModel>> getMyPayments() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/payments/my'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final list = data['payments'] as List? ?? [];
      return list.map((e) => PaymentModel.fromJson(e)).toList();
    } else {
      final err = json.decode(response.body);
      throw Exception(err['message'] ?? 'Gagal memuat riwayat pembayaran');
    }
  }
}
