import 'dart:convert';
import 'api_helper.dart';

class CashSessionService {
  // Open cash session
  static Future<Map<String, dynamic>> startSession(double openingAmount) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/cash-sessions/open',
        body: {'openingAmount': openingAmount},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Sesión iniciada exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Close cash session
  static Future<Map<String, dynamic>> closeSession(String sessionId) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/cash-sessions/close/$sessionId',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {};
        return {
          'success': true,
          'message': 'Sesión cerrada exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get current open session
  static Future<Map<String, dynamic>> getOpenSession() async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/cash-sessions/open',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Sesión obtenida exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}
