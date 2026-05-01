  import 'dart:convert';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'package:http/http.dart' as http;
  import 'package:flutter/foundation.dart' show kIsWeb;
  import 'package:pv26/core/network/api_helper.dart';
  import 'package:flutter/services.dart';

  class AuthService {
    static const String _accessTokenKey = 'access_token';
    static const String _refreshTokenKey = 'refresh_token';
    static const String _userEmailKey = 'user_email';
    static const String _userNameKey = 'user_name';
    static const String _userRoleKey = 'user_role';
    static const String _baseUrl = 'https://punto-de-venta-mu.vercel.app/api';
    static const String _userOnboardingKey = 'user_onboarding';
    static const String _userLogoKey = 'user_logo';
    static const String _userLocations = 'user_locations';
    static const String _userCurrentLocation = 'user_current_location';


    // Register with real API call
    static Future<Map<String, dynamic>> register(
      String name,
      String email,
      String phone,

    ) async {
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
            'phone': phone, 
          
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
    static Future<Map<String, dynamic>> login(
      String email,
      String password,
    ) async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'email': email, 'password': password}),
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          // Extract tokens from headers
          final accessToken =
              response.headers['x-access-token'] ??
              response.headers['X-Access-Token'] ??
              response.headers['authorization']?.replaceFirst('Bearer ', '') ??
              '';
          final refreshToken =
              response.headers['x-refresh-token'] ??
              response.headers['X-Refresh-Token'] ??
              '';

          // Extract user data from response body
          final userData = responseData['user'] ?? {};

          final userName = userData['userName'] ?? '';
          final userEmail = userData['email'] ?? email;
          final userRole = userData['role'] ?? 'cajero'; 
          final userLogo = userData['logoUrl'] ?? '';
          final userLocations = userData['locations'] ?? [];
          final userCurrentLocation = userData['currentLocation'] ?? '';

          final onboardingStatus = userData['onboarding'] ?? {
            'isCompleted': false,
            'stepsCompleted': {
              'home': false,
              'inventory': false,
              'sales': false,
              'users': false,
              'reports': false,
            }
          };

          // Store tokens and user data
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_accessTokenKey, accessToken);
          await prefs.setString(_refreshTokenKey, refreshToken);
          await prefs.setString(_userNameKey, userName);
          await prefs.setString(_userEmailKey, userEmail);
          await prefs.setString(_userRoleKey, userRole);
          await prefs.setString(_userOnboardingKey, jsonEncode(onboardingStatus));
          await prefs.setString(_userLogoKey, userLogo);
          await prefs.setString(_userLocations, jsonEncode(userLocations));
          await prefs.setString(_userCurrentLocation, userCurrentLocation);

       

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
          return {'success': false, 'message': 'Credenciales incorrectas'};
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
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);

        return {
          'success': true,
          'message':
              responseData['message'] ?? 'Instrucciones enviadas a tu correo',
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
          body: jsonEncode({'refreshToken': refreshToken}),
        );

        // Clear local storage regardless of API response
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userNameKey);
        await prefs.remove(_userEmailKey);
        await prefs.remove(_userRoleKey);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {'success': true, 'message': 'Sesión cerrada exitosamente'};
        } else {
          // Even if API call fails, local logout is successful
          return {'success': true, 'message': 'Sesión cerrada localmente'};
        }
      } else {
        // No refresh token, just clear local storage
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userNameKey);
        await prefs.remove(_userEmailKey);
        await prefs.remove(_userRoleKey);

        return {'success': true, 'message': 'Sesión cerrada localmente'};
      }
    } catch (e) {
      // Even if API call fails, try to clear local storage
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_accessTokenKey);
        await prefs.remove(_refreshTokenKey);
        await prefs.remove(_userNameKey);
        await prefs.remove(_userEmailKey);
        await prefs.remove(_userRoleKey);
      } catch (_) {}

      return {'success': true, 'message': 'Sesión cerrada localmente'};
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

  // Get current user role
  static Future<String?> getCurrentUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

    // Get current user role
  static Future<String?> getCurrentUserLocation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userCurrentLocation);
  }

  // Get user data object
  static Future<Map<String, String>?> getCurrentUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(_userEmailKey);
    final name = prefs.getString(_userNameKey);

    if (email != null && name != null) {
      return {'email': email, 'userName': name};
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
        return {'success': false, 'message': 'No refresh token available'};
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh-token'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        }
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final newAccessToken = response.headers['x-access-token'];

        if (newAccessToken == null || newAccessToken.isEmpty) {
          return {
            'success': false,
            'message': 'No access token returned in headers'
          };
        }

        // Update access token
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString(
          _accessTokenKey,
          newAccessToken,
        );

        return {
          'success': true,
          'message': responseData['message'] ?? 'Token refreshed successfully',
          'data': newAccessToken,
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




    
    static Future<Map<String, dynamic>> registerCompany({
      required String name,
      required String email,
      required String phone,
      dynamic logo, // File o XFile
    }) async {
      try {
        final path = '/auth/registerCompany';

        final fields = {
          'name': name,
          'email': email,
          'phone': phone,
        };

        http.Response response;

          // if (kIsWeb) {
          //   if (logo != null) {
          //     final bytes = await logo.readAsBytes();
          //     final filename = logo.name;

          //     response = await ApiHelper.requestMultipartWeb(
          //       path: path,
          //       bytes: bytes,
          //       filename: filename,
          //       fileField: 'logo',
          //       fields: fields,
          //     );
          //   } else {
          //     response = await ApiHelper.requestMultipartWeb(
          //       path: path,
          //       bytes: Uint8List(0), // no se manda archivo
          //       filename: '',
          //       fileField: '',
          //       fields: fields,
          //     );
          //   }
          // } else {
          //   response = await ApiHelper.requestMultipart(
          //     path: path,
          //     file: logo, // puede ser null si tu helper lo soporta
          //     fileField: 'logo',
          //     fields: fields,
          //   );
          // }


        if (kIsWeb && logo != null) {
          final bytes = await logo.readAsBytes();

          response = await ApiHelper.requestMultipartWeb(
            path: path,
            bytes: bytes,
            filename: logo.name,
            fileField: 'logo',
            fields: fields,
          );
        } else if (!kIsWeb && logo != null) {
          response = await ApiHelper.requestMultipart(
            path: path,
            file: logo,
            fileField: 'logo',
            fields: fields,
          );
        } else {
          // ❌ NO mandar multipart si no hay archivo
          response = await ApiHelper.request(
           method: 'POST',
            path: path,
            body: fields,
          );
        }

            final respStr = response.body;
        final data = jsonDecode(respStr);

        if (response.statusCode == 200 || response.statusCode == 201) {
          return {
            'success': true,
            'message': data['message'] ?? 'Empresa creada correctamente',
            'data': data,
          };
        }

        return {
          'success': false,
          'message': data['message'] ?? 'Error (${response.statusCode})',
        };
      } catch (e) {
        return {
          'success': false,
          'message': 'Error: $e',
        };
      }
    }



}


