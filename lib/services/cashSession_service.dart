import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';


class CashSessionService {
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

  //Open cash session
  static Future<Map<String, dynamic>> startSession(double openingAmount) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/cash-sessions/open'),
        headers: headers,
        body: jsonEncode({
          'openingAmount': openingAmount
          }),
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
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }


//Close cash session

static Future<Map<String, dynamic>> closeSession(String sessionId) async {
    try {
      final headers = await _getHeaders();

      
      
      final response = await http.post(
        Uri.parse('$_baseUrl/cash-sessions/close/$sessionId'),
        headers: headers
        
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        
        return {
          'success': true,
          'message': 'Sesión cerrada exitosamente',
          'data': responseData,
        };
      } else {
         final errorData = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error desconocido',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  } 


  //Get current session or open session
  static Future<Map<String, dynamic>> getOpenSession() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        headers: headers,
        Uri.parse('$_baseUrl/cash-sessions/open')
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
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

}
