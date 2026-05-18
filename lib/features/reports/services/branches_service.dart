import 'dart:convert';
import 'package:pv26/core/network/api_helper.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;


class BranchesService {
  
  //Create location

  static Future<Map<String, dynamic>> createLocation({
    required String name,
    required String address,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/locations',
        body: {
          'name': name,
          'address': address,
        }
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Ubicación creada exitosamente',
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

  //Get locations
  static Future<Map<String, dynamic>> getLocations() async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/locations',
      );

     if (response.statusCode == 200 || response.statusCode == 201){
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


  //Create location
  static Future<Map<String, dynamic>> createLocationFromCreator({
    required String name,
    required String address,
    required String companyId,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/locations/from-creator',
        body: {
          'name': name,
          'address': address,
          'masterId': companyId,
        }
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Ubicación creada exitosamente',
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

  //Update location
  static Future<Map<String, dynamic>> updateLocation({
    required String companyId,
    required String name,
    required String address,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'PUT',
        path: '/locations/$companyId',
        body: {
          'name': name,
          'address': address,
        }

      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Sucursal actualizada exitosamente',
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



  //Delete location
  static Future<Map<String, dynamic>> deleteLocation({
    required String companyId,
  }) async
  {
    try {

      final response = await ApiHelper.request(
        method: 'DELETE',
        path: '/locations/$companyId',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
            return {
              'success': true,
              'message': data['message'] ?? 'Sucursal eliminada correctamente',
              'data': data,
            };
          } else {
            return {
              'success': false,
              'message': data['message'] ?? 'Error al eliminar la sucursal',
            };
          }

    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }
        

  //Create category
  static Future<Map<String, dynamic>> addCategory({
      required String id,
      required String category,
    }) async {
      try {

        print('id: $id, category: $category'); 

        final response = await ApiHelper.request(
          method: 'POST',
          path: '/locations/categories/$id',
          body: {
            'category': category 
          }
        );

         print(response); 

        if (response.statusCode == 200 || response.statusCode == 201) {
          final responseData = jsonDecode(response.body);
          return {
            'success': true,
            'message': 'Departamento creado exitosamente',
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


  //Get categories 
  static Future<Map<String, dynamic>> getCategories({
    required String id,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/locations/categories/$id',
      );

     if (response.statusCode == 200 || response.statusCode == 201){
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



  
  //Delete categories
  static Future<Map<String, dynamic>> deleteCategories({
    required String id,
  }) async
  {
    try {

      final response = await ApiHelper.request(
        method: 'DELETE',
        path: '/locations/categories/$id',
      );

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
            return {
              'success': true,
              'message': data['message'] ?? 'Departamento eliminado correctamente',
              'data': data,
            };
          } else {
            return {
              'success': false,
              'message': data['message'] ?? 'Error al eliminar el departamento',
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