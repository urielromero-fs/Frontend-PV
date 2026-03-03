import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class WithdrawalService {
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

  // Create withdrawal with real API call
  static Future<Map<String, dynamic>> createWithdrawal({
    required double amount,
    required String reason,
  }) async {
    try {
      final headers = await _getHeaders();

      print('Creating withdrawal with amount: $amount, reason: $reason');

      final response = await http.post(
        Uri.parse('$_baseUrl/withdrawals'),
        headers: headers,
        body: jsonEncode({
          'amount': amount,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Retiro creado exitosamente',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al crear el retiro: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al crear el retiro: $e'};
    }
  }



}