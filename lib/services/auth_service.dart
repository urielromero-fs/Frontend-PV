import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _baseUrl = 'https://punto-de-venta-mu.vercel.app/api';

  // Register with real API call
  static Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'message': 'Cuenta creada exitosamente',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Datos inválidos',
        };
      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'El email ya está registrado',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Login with real API call
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );




      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        // Extract tokens from headers
        final accessToken = response.headers['x-access-token'] ?? response.headers['X-Access-Token'] ?? response.headers['authorization']?.replaceFirst('Bearer ', '') ?? '';
        final refreshToken = response.headers['x-refresh-token'] ?? response.headers['X-Refresh-Token'] ?? '';
        
        // Extract user data from response body
        final userData = responseData['user'] ?? {};
        final userName = userData['userName'] ?? '';
        final userEmail = userData['email'] ?? email;
        
        // Store tokens and user data
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, accessToken);
        await prefs.setString(_refreshTokenKey, refreshToken);
        await prefs.setString(_userNameKey, userName);
        await prefs.setString(_userEmailKey, userEmail);
        
        return {
          'success': true,
          'message': 'Login exitoso',
          'data': {
            'user': userData,
            'accessToken': accessToken,
            'refreshToken': refreshToken,
          },
        };
      } else if (response.statusCode == 401) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Credenciales incorrectas',
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Datos inválidos',
        };
      } else if (response.statusCode == 409) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'El email ya está registrado',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Forgot password with real API call
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'message': responseData['message'] ?? 'Instrucciones enviadas a tu correo',
          'data': responseData,
        };
      } else if (response.statusCode == 404) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Correo no encontrado',
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Correo inválido',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Logout with real API call
  static Future<Map<String, dynamic>> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      
      if (refreshToken != null) {
        // Make API call to logout
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'refreshToken': refreshToken,
          }),
        );

        // Clear local storage regardless of API response
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userNameKey);
        await prefs.remove(_userEmailKey);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': 'Sesión cerrada exitosamente',
          };
        } else {
          // Even if API call fails, local logout is successful
          return {
            'success': true,
            'message': 'Sesión cerrada localmente',
          };
        }
      } else {
        // No refresh token, just clear local storage
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userNameKey);
        await prefs.remove(_userEmailKey);
        
        return {
          'success': true,
          'message': 'Sesión cerrada localmente',
        };
      }
    } catch (e) {
      // Even if API call fails, try to clear local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userNameKey);
        await prefs.remove(_userEmailKey);
      } catch (_) {}
      
      return {
        'success': true,
        'message': 'Sesión cerrada localmente',
      };
    }
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_accessTokenKey);
    return token != null && token.isNotEmpty;
  }

  // Get current user email
  static Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  // Get current user name
  static Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  // Get user data object
  static Future<Map<String, String>?> getCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmailKey);
    final name = prefs.getString(_userNameKey);
    
    if (email != null && name != null) {
      return {
        'email': email,
        'userName': name,
      };
    }
    return null;
  }

  // Get access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  // Get refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  // Get auth token (for backward compatibility)
  static Future<String?> getAuthToken() async {
    return await getAccessToken();
  }

  // Refresh access token using refresh token
  static Future<Map<String, dynamic>> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) {
        return {
          'success': false,
          'message': 'No refresh token available',
        };
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'refreshToken': refreshToken,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Update access token
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_accessTokenKey, responseData['accessToken'] ?? '');
        
        return {
          'success': true,
          'message': 'Token refreshed successfully',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to refresh token',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error refreshing token: ${e.toString()}',
      };
    }
  }

  // Validate token with server
  static Future<bool> validateToken() async {
    try {
      final token = await getAuthToken();
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/validate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
