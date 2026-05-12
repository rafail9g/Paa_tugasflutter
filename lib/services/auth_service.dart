import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:paa_gacor/config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:paa_gacor/models/user_model.dart';

class AuthService {
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accessToken', accessToken);
    await prefs.setString('refreshToken', refreshToken);
    if (role != null) {
      await prefs.setString('role', role);
    }
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');
    await prefs.remove('role');
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ==================== AUTH ENDPOINTS ====================

  /// Register — sesuai API spec:
  /// { name, email, password, phone, address: { street, city, province, zipCode },
  ///   drivingLicense: { number, expiryDate } }
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    String? street,
    String? city,
    String? province,
    String? zipCode,
    String? licenseNumber,
    DateTime? licenseExpiry,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.authPrefix}/register',
    );

    // Build body sesuai struktur API
    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
    };

    // Tambahkan address jika ada salah satu field yang diisi
    final hasAddress =
        (street != null && street.isNotEmpty) ||
        (city != null && city.isNotEmpty) ||
        (province != null && province.isNotEmpty) ||
        (zipCode != null && zipCode.isNotEmpty);

    if (hasAddress) {
      body['address'] = {
        if (street != null && street.isNotEmpty) 'street': street,
        if (city != null && city.isNotEmpty) 'city': city,
        if (province != null && province.isNotEmpty) 'province': province,
        if (zipCode != null && zipCode.isNotEmpty) 'zipCode': zipCode,
      };
    }

    // Tambahkan drivingLicense jika ada
    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      body['drivingLicense'] = {
        'number': licenseNumber,
        if (licenseExpiry != null)
          'expiryDate': licenseExpiry.toIso8601String().substring(0, 10),
      };
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(body),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 201) {
      final data = responseBody['data'];
      final user = UserModel.fromJson(data['user']);
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: user.role,
      );

      return {
        'user': user,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
    } else {
      // Ambil pesan error yang lebih spesifik jika ada
      String errorMsg = responseBody['message'] ?? 'Registrasi gagal';
      if (responseBody['errors'] != null) {
        final errors = responseBody['errors'] as List;
        if (errors.isNotEmpty) {
          errorMsg = errors.map((e) => e['message'] ?? e.toString()).join(', ');
        }
      }
      throw Exception(errorMsg);
    }
  }

  /// Login pengguna
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authPrefix}/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      final data = body['data'];
      final user = UserModel.fromJson(data['user']);
      final accessToken = data['accessToken'] as String;
      final refreshToken = data['refreshToken'] as String;

      await saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        role: user.role,
      );

      return {
        'user': user,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
    } else {
      throw Exception(body['message'] ?? 'Login gagal');
    }
  }

  /// Ambil profil user yang sedang login
  static Future<UserModel> getMe() async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.authPrefix}/me');
    final headers = await _authHeaders();

    final response = await http.get(url, headers: headers);
    final body = json.decode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(body['data']['user']);
    } else {
      throw Exception(body['message'] ?? 'Gagal mengambil data profil');
    }
  }

  /// Update profil
  static Future<UserModel> updateProfile({
    String? name,
    String? phone,
    String? street,
    String? city,
    String? province,
    String? zipCode,
    String? licenseNumber,
    DateTime? licenseExpiry,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/users/profile');
    final headers = await _authHeaders();

    final Map<String, dynamic> body = {};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;

    final hasAddress =
        (street != null && street.isNotEmpty) ||
        (city != null && city.isNotEmpty) ||
        (province != null && province.isNotEmpty) ||
        (zipCode != null && zipCode.isNotEmpty);
    if (hasAddress) {
      body['address'] = {
        if (street != null && street.isNotEmpty) 'street': street,
        if (city != null && city.isNotEmpty) 'city': city,
        if (province != null && province.isNotEmpty) 'province': province,
        if (zipCode != null && zipCode.isNotEmpty) 'zipCode': zipCode,
      };
    }

    if (licenseNumber != null && licenseNumber.isNotEmpty) {
      body['drivingLicense'] = {
        'number': licenseNumber,
        if (licenseExpiry != null)
          'expiryDate': licenseExpiry.toIso8601String().substring(0, 10),
      };
    }

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode(body),
    );

    final responseBody = json.decode(response.body);
    if (response.statusCode == 200) {
      return UserModel.fromJson(responseBody['data']['user']);
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal update profil');
    }
  }

  /// Logout pengguna
  static Future<void> logout() async {
    try {
      final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.authPrefix}/logout',
      );
      final headers = await _authHeaders();
      await http.post(url, headers: headers);
    } catch (_) {
      // Tetap hapus token meskipun request gagal
    }
    await clearTokens();
  }

  /// Ganti password
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.authPrefix}/update-password',
    );
    final headers = await _authHeaders();

    final response = await http.put(
      url,
      headers: headers,
      body: json.encode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      }),
    );

    final body = json.decode(response.body);
    if (response.statusCode != 200) {
      throw Exception(body['message'] ?? 'Gagal mengganti password');
    }
  }
}
