import 'dart:convert';
import 'api_helper.dart';

class WithdrawalService {
  // Create withdrawal with automatic token refresh
  static Future<Map<String, dynamic>> createWithdrawal({
    required double amount,
    required String reason,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/withdrawals',
        body: {
          'amount': amount,
          'reason': reason,
        },
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