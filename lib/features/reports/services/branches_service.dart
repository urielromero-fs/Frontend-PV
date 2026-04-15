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

}