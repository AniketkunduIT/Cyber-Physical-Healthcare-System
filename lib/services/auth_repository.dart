import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import 'api_config.dart';

/// Connects authentication directly to the FastAPI backend.
class AuthRepository {
  Future<UserModel> login({
    required String usernameOrPhone,
    required String password,
  }) async {
    if (usernameOrPhone.trim().isEmpty || password.trim().isEmpty) {
      throw Exception('Please enter both your username/phone and password.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/login');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'username_or_phone': usernameOrPhone.trim(),
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = data['token'] as String;
        ApiConfig.authToken = token;

        return UserModel(
          id: data['id'] as String,
          name: data['name'] as String,
          usernameOrPhone: data['username_or_phone'] as String? ?? usernameOrPhone,
          email: data['email'] as String?,
          token: token,
        );
      } else {
        final errorMsg = data['detail'] ?? 'Incorrect username or password. Please try again.';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed host lookup') && !e.toString().contains('Connection refused')) {
        rethrow;
      }
      throw Exception('Cannot connect to authentication service at ${ApiConfig.baseUrl}. Please check server status.');
    }
  }

  Future<UserModel> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    if (name.trim().isEmpty || phone.trim().isEmpty || password.length < 4) {
      throw Exception('Please fill all fields with a valid password.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/register');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'name': name.trim(),
          'username_or_phone': phone.trim(),
          'email': email.trim().isNotEmpty ? email.trim() : null,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final token = data['token'] as String;
        ApiConfig.authToken = token;

        return UserModel(
          id: data['id'] as String,
          name: data['name'] as String,
          usernameOrPhone: data['username_or_phone'] as String? ?? phone,
          email: data['email'] as String? ?? email,
          token: token,
        );
      } else {
        final errorMsg = data['detail'] ?? 'Failed to create account.';
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed host lookup') && !e.toString().contains('Connection refused')) {
        rethrow;
      }
      throw Exception('Cannot connect to registration service at ${ApiConfig.baseUrl}. Please check server status.');
    }
  }

  Future<void> sendPasswordReset({required String contact}) async {
    if (contact.trim().isEmpty) {
      throw Exception('Enter the phone number or email linked to your account.');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}/api/auth/reset-password');
    try {
      final response = await http.post(
        url,
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'contact': contact.trim()}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final data = jsonDecode(response.body);
        throw Exception(data['detail'] ?? 'Failed to send reset link.');
      }
    } catch (e) {
      if (e is Exception && !e.toString().contains('Failed host lookup') && !e.toString().contains('Connection refused')) {
        rethrow;
      }
      throw Exception('Cannot reach server for password reset.');
    }
  }
}
