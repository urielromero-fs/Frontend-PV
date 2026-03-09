  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'auth_service.dart';

  class ApiHelper {
    static const String _baseUrl = 'https://punto-de-venta-mu.vercel.app/api';

    static Future<Map<String, String>> _getHeaders() async {

      final token = await AuthService.getAccessToken();
      
      return {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
    }

    static Future<http.Response> request({
      required String method,
      required String path,
      dynamic body,
    }) async {
      final url = Uri.parse('$_baseUrl$path');
      final headers = await _getHeaders();
      
      http.Response response;
      
      // Perform initial request
      response = await _executeRequest(method, url, headers, body);

      // If 401 Unauthorized, try to refresh token
      if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshAccessToken();
        
        if (refreshResult['success'] == true) {
          // Retry with new token
          final newHeaders = await _getHeaders();
          response = await _executeRequest(method, url, newHeaders, body);
        }
      }

      return response;
    }

    static Future<http.Response> _executeRequest(
      String method,
      Uri url,
      Map<String, String> headers,
      dynamic body,
    ) async {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PUT':
          return await http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'DELETE':
          return await http.delete(url, headers: headers);
        default:
          throw Exception('HTTP Method $method not supported');
      }
    }
  }
