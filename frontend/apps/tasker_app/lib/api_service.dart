import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://taskly-tasker-backend.onrender.com';

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String idNumber,
    required List<String> categories,
    required String city,
    required String area,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');

    var formattedPhone = phone.replaceAll('+', '').replaceAll(' ', '').trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '254' + formattedPhone.substring(1);
    }
    if (!formattedPhone.startsWith('254')) {
      formattedPhone = '254' + formattedPhone;
    }

    final body = {
      'phone_number': formattedPhone,
      'password': password,
      'full_name': name,
      'email': email,
      'id_number': idNumber,
      'categories': categories,
      'location_city': city,
      'location_area': area,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful!',
          'user_id': data['user_id'],
        };
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Registration failed. Please try again.',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to connect to the server: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');

    var username = phoneOrEmail.replaceAll('+', '').replaceAll(' ', '').trim();
    if (username.startsWith('0')) {
      username = '254' + username.substring(1);
    }
    if (username.length >= 9 && !username.contains('@') && !username.startsWith('254')) {
      username = '254' + username;
    }

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': username,
          'password': password,
        },
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'access_token': data['access_token'],
        };
      } else {
        final errorMsg = data is Map && data.containsKey('detail')
            ? data['detail'].toString()
            : 'Account not registered. Please sign up first.';
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Account not registered. Please sign up first.',
      };
    }
  }

  static Future<Map<String, dynamic>> googleSignIn({
    required String email,
    String? name,
    String? photoUrl,
    String? idToken,
  }) async {
    final url = Uri.parse('$baseUrl/auth/google');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'full_name': name?.trim(),
          'photo_url': photoUrl,
          'id_token': idToken,
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {}

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'access_token': data is Map ? data['access_token'] : null,
          'user': data is Map ? data['user'] : null,
          'message': data is Map && data.containsKey('message')
              ? data['message']
              : 'Signed in with Google successfully!',
        };
      } else {
        final errorMsg = data is Map && data.containsKey('detail')
            ? data['detail'].toString()
            : 'Google authentication failed.';
        return {
          'success': false,
          'message': errorMsg,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to server. Please try again.',
      };
    }
  }
}
