import 'dart:convert';
import 'package:pv26/core/network/api_helper.dart';


class UsersService {
  
  //Create user

  static Future<Map<String, dynamic>> createUser({
    required String name,
    required String email, 
    required String role,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/users',
        body: {
          'name': name,
          'email': email,
          'role': role,
        }
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Usuario creado exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor (${response.statusCode})',
        };
      }
    } catch (e) { 
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }

  }


  //Get users
  static Future<Map<String, dynamic>> getUsers() async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/users',
      );
    
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor (${response.statusCode})',
        };
      }

    } catch (e) { 
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }

  }


  //Send new password 
  static Future<Map<String, dynamic>> sendNewPassword({
    required String email,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/auth/reset-password',
        body: {
          'email': email,
        }
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Correo de recuperación enviado exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor (${response.statusCode})',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }


  // Update user
  static Future<Map<String, dynamic>> updateUser({
    required String id,
    String? name,
    String? email, 
    String? role,
    
  }) async {

  

    try {
      final response = await ApiHelper.request(
        method: 'PUT',
        path: '/users/$id',
        body: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (role != null) 'role': role,
        }
      ); 

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Usuario actualizado exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor (${response.statusCode})',
        };
      }

    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }

  }


  //Delete user
  static Future<Map<String, dynamic>> deleteUser({
    required String id,
  }) async {
    try {

      print(  'Attempting to delete user with ID: $id'); // Debug log

      final response = await ApiHelper.request(
        method: 'DELETE',
        path: '/users/$id',
      );

       if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Usuario eliminado exitosamente',
        };
      } else {
        
        Map<String, dynamic> errorData = {};
        if (response.body.isNotEmpty) {
          errorData = jsonDecode(response.body);
        }
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor (${response.statusCode})',
        };
      } 

    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }

  }
      
  //inactivate user
  static Future<Map<String, dynamic>> inactivateUser({
    required String id,
  }) async {

  

    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/users/inactivate/$id'
      ); 

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Usuario eliminado',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor (${response.statusCode})',
        };
      }

    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }

  }



  // Update Admin 
  static Future<Map<String, dynamic>> updateAdminUser({
    String? name,
    String? email, 
    String? password,
  }) async {



    try {
      final response = await ApiHelper.request(
        method: 'PUT',
        path: '/users/updateCompanyAdmin',
        body: {
          if (name != null) 'name': name,
          if (email != null) 'email': email,
          if (password != null) 'password': password,
        }
      ); 



      if (response.statusCode == 200) {


        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Usuario admin actualizado exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error en el servidor (${response.statusCode})',
        };
      }

    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }

  }



    



}