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

  // Create a new booking
  static Future<BookingModel> createBooking({
    required String carId,
    required DateTime startDate,
    required DateTime endDate,
    String? notes,
    String? pickupLocation,
    String? dropoffLocation,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix');
    final headers = await _authHeaders();

    final totalDays = endDate.difference(startDate).inDays;

    final body = {
      'car': carId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDays': totalDays,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (pickupLocation != null && pickupLocation.isNotEmpty) 'pickupLocation': pickupLocation,
      if (dropoffLocation != null && dropoffLocation.isNotEmpty) 'dropoffLocation': dropoffLocation,
    };

    final response = await http.post(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal membuat pemesanan');
    }
  }

  // Get user's own bookings
  static Future<List<BookingModel>> getMyBookings({String? status}) async {
    final queryParams = <String, String>{};
    if (status != null && status.isNotEmpty) queryParams['status'] = status;

    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/my')
        .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
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

  // Get all bookings (Admin)
  static Future<List<BookingModel>> getAllBookings({
    String? status,
    String? paymentStatus,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) queryParams['status'] = status;
    if (paymentStatus != null && paymentStatus.isNotEmpty) queryParams['paymentStatus'] = paymentStatus;

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
      throw Exception(body['message'] ?? 'Gagal mengambil semua data pemesanan');
    }
  }

  // Get single booking by ID
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

  // Admin: Update booking status (confirm / cancel / complete)
  static Future<BookingModel> updateBookingStatus(String id, String status, {String? notes}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$id/status');
    final headers = await _authHeaders();

    final body = <String, dynamic>{'status': status};
    if (notes != null && notes.isNotEmpty) body['notes'] = notes;

    final response = await http.patch(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal memperbarui status pemesanan');
    }
  }

  // User: Cancel booking
  static Future<BookingModel> cancelBooking(String id, {String? reason}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$id/cancel');
    final headers = await _authHeaders();

    final body = <String, dynamic>{};
    if (reason != null && reason.isNotEmpty) body['reason'] = reason;

    final response = await http.patch(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal membatalkan pemesanan');
    }
  }

  // Admin: Verify / reject payment
  static Future<BookingModel> verifyPayment(
    String bookingId, {
    required bool isVerified,
    String? adminNotes,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$bookingId/payment/verify');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      'isVerified': isVerified,
      if (adminNotes != null && adminNotes.isNotEmpty) 'adminNotes': adminNotes,
    };

    final response = await http.patch(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal memverifikasi pembayaran');
    }
  }

  // User: Submit payment proof
  static Future<BookingModel> submitPayment(
    String bookingId, {
    required String method,
    required double amount,
    String? proofUrl,
    String? notes,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}$_prefix/$bookingId/payment');
    final headers = await _authHeaders();

    final body = <String, dynamic>{
      'method': method,
      'amount': amount,
      if (proofUrl != null && proofUrl.isNotEmpty) 'proofUrl': proofUrl,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    final response = await http.post(url, headers: headers, body: json.encode(body));
    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = responseBody['data'];
      return BookingModel.fromJson(data['booking'] ?? data);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal mengirim bukti pembayaran');
    }
  }
}