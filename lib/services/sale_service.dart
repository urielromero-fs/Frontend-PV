import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SaleService {
  static const String _baseUrl = 'https://punto-de-venta-mu.vercel.app/api';

  // Get authorization headers
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create sale with real API call
  static Future<Map<String, dynamic>> createSale({
    required List<Map<String, dynamic>> products,
  }) async {
    try {
      final headers = await _getHeaders();

      final response = await http.post(
        Uri.parse('$_baseUrl/sale'),
        headers: headers,
        body: jsonEncode({'products': products}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Venta creada exitosamente',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al crear la venta: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al crear la venta: $e'};
    }
  }
}
