import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Excepcion tipada para errores de API: el backend siempre responde
/// {"error": true, "message": "...", "error_code": "..."} en fallos.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;

  ApiException({required this.statusCode, required this.message, this.errorCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Unico punto por donde pasa CADA llamada HTTP de la app.
class ApiClient {
  static const String _tokenKey = 'access_token';

  static Future<void> guardarToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> limpiarToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool conAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (conAuth) {
      final token = await obtenerToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static dynamic _procesarRespuesta(http.Response response) {
    final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final mensaje = (body is Map && body['message'] != null)
        ? body['message'] as String
        : (body is Map && body['detail'] != null)
            ? body['detail'].toString()
            : 'Error ${response.statusCode}';
    final errorCode = (body is Map && body['error_code'] != null) ? body['error_code'] as String : null;

    throw ApiException(statusCode: response.statusCode, message: mensaje, errorCode: errorCode);
  }

  static Future<dynamic> get(String url, {bool conAuth = true}) async {
    final response = await http.get(Uri.parse(url), headers: await _headers(conAuth: conAuth));
    return _procesarRespuesta(response);
  }

  static Future<dynamic> post(String url, {Map<String, dynamic>? body, bool conAuth = true}) async {
    final response = await http.post(
      Uri.parse(url),
      headers: await _headers(conAuth: conAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _procesarRespuesta(response);
  }

  static Future<dynamic> put(String url, {Map<String, dynamic>? body, bool conAuth = true}) async {
    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(conAuth: conAuth),
      body: body != null ? jsonEncode(body) : null,
    );
    return _procesarRespuesta(response);
  }

  static Future<dynamic> delete(String url, {bool conAuth = true}) async {
    final response = await http.delete(Uri.parse(url), headers: await _headers(conAuth: conAuth));
    return _procesarRespuesta(response);
  }
}
