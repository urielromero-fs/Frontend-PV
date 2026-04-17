import 'dart:convert';
import 'package:pv26/core/network/api_helper.dart';

class CashSessionService {
  // Open cash session
  static Future<Map<String, dynamic>> startSession(
    double openingAmount, 
    String locationId

    ) async {
    try {

      print({
        'openingAmount': openingAmount,
        'locationId': locationId
      });

      final response = await ApiHelper.request(
        method: 'POST',
        path: '/cash-sessions/open/$locationId',
        body: {'openingAmount': openingAmount},
      );  

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

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
  static Future<Map<String, dynamic>> getOpenSession(String locationId) async {
    try {

      print(locationId);
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/cash-sessions/open/$locationId',
      );

      print(response.body);

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

  //Get session history
  static Future<Map<String, dynamic>> getSessionHistory(String sessionId) async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/cash-sessions/history/$sessionId'
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Historial de sesión obtenido exitosamente',
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
