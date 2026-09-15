import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {"Content-Type": "application/json"};
    if (withAuth) {
      final token = await StorageService.getToken();
      if (token != null) headers["Authorization"] = "Bearer $token";
    }
    return headers;
  }

  static dynamic _decode(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message = (body is Map && body["message"] != null)
        ? body["message"].toString()
        : "Something went wrong (${response.statusCode})";
    throw ApiException(response.statusCode, message);
  }

  static Future<dynamic> get(String path, {bool withAuth = true}) async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
    );
    return _decode(response);
  }

  static Future<dynamic> post(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> put(
    String path,
    Map<String, dynamic> body, {
    bool withAuth = true,
  }) async {
    final response = await http.put(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
      body: jsonEncode(body),
    );
    return _decode(response);
  }

  static Future<dynamic> delete(String path, {bool withAuth = true}) async {
    final response = await http.delete(
      Uri.parse("${ApiConfig.baseUrl}$path"),
      headers: await _headers(withAuth: withAuth),
    );
    return _decode(response);
  }
}
