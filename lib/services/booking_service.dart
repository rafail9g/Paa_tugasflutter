import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paa_gacor/config/api_config.dart';
import 'package:paa_gacor/models/booking.dart';
import 'package:paa_gacor/services/auth_service.dart';

class BookingService {
  static const String _prefix = '/api/bookings';

  static Future<Map<String, String>> _authHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── Buat pemesanan baru ──────────────────────────────────────────────────
  static Future<BookingModel> createBooking({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? pickupLocation,
    String? returnLocation,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      'car': carId,
      'startDate': startDate.toIso8601String().substring(0, 10), // YYYY-MM-DD
      'endDate': endDate.toIso8601String().substring(0, 10),
      if (pickupLocation != null && pickupLocation.isNotEmpty)
        'pickupLocation': pickupLocation,
      if (returnLocation != null && returnLocation.isNotEmpty)
        'returnLocation': returnLocation,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response =
        await http.post(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal membuat pemesanan');
    }
  }

  // ── Ambil semua pemesanan (user: miliknya saja, admin: semua) ───────────
  static Future<List<BookingModel>> getMyBookings({
    String? status,
    int page = 1,
    int limit = 20,
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
      final List<dynamic> bookingsJson = data['bookings'] ?? data ?? [];
      return bookingsJson.map((j) => BookingModel.fromJson(j)).toList();
    } else {
      throw Exception(body['message'] ?? 'Gagal mengambil data pemesanan');
    }
  }

  // ── Admin: ambil semua pemesanan ─────────────────────────────────────────
  static Future<List<BookingModel>> getAllBookings({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    // Sama endpoint, admin otomatis dapat semua dari server
    return getMyBookings(status: status, page: page, limit: limit);
  }

  // ── Ambil detail satu pemesanan ──────────────────────────────────────────
  static Future<BookingModel> getBookingById(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$id');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);
    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = body['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(body['message'] ?? 'Pemesanan tidak ditemukan');
    }
  }

  // ── Admin: konfirmasi pemesanan (pending → confirmed) ────────────────────
  static Future<BookingModel> confirmBooking(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$id/confirm');
    final headers = await _authHeaders();

    final response = await http.put(url, headers: headers);
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(
          responseBody['message'] ?? 'Gagal mengkonfirmasi pemesanan');
    }
  }

  // ── Admin: selesaikan pemesanan (active → completed) ─────────────────────
  static Future<BookingModel> completeBooking(String id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$id/complete');
    final headers = await _authHeaders();

    final response = await http.put(url, headers: headers);
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(
          responseBody['message'] ?? 'Gagal menyelesaikan pemesanan');
    }
  }

  // ── User/Admin: batalkan pemesanan ───────────────────────────────────────
  static Future<BookingModel> cancelBooking(String id,
      {String? reason}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$id/cancel');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

    final response =
        await http.put(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(
          responseBody['message'] ?? 'Gagal membatalkan pemesanan');
    }
  }

  // ── Admin: verifikasi pembayaran via payment ID ──────────────────────────
  // Dipindah ke PaymentService — lihat verifyPayment di sana

  // Wrapper untuk admin_bookings.dart yang masih pakai nama lama
  static Future<BookingModel> updateBookingStatus(
      String id, String status) async {
    switch (status) {
      case 'confirmed':
        return confirmBooking(id);
      case 'completed':
        return completeBooking(id);
      case 'cancelled':
        return cancelBooking(id);
      default:
        throw Exception('Status tidak dikenali: $status');
    }
  }
}