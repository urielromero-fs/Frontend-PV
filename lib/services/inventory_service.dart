import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class InventoryService {
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

  // Create product with real API call
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String barcode,
    required bool isBulk,
    required double weight,
    required int units,
    required double buyingPrice,
    required double sellingPrice,
    required double bulkPrice,
    required bool hasWholesalePrice,
    required double wholesalePrice,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$_baseUrl/products'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'barcode': barcode,
          'isBulk': isBulk,
          'weight': weight,
          'units': units,
          'buyingPrice': buyingPrice,
          'sellingPrice': sellingPrice,
          'bulkPrice': bulkPrice,
          'hasWholesalePrice': hasWholesalePrice,
          'wholesalePrice': wholesalePrice,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'message': 'Producto creado exitosamente',
          'data': responseData,
        };
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Datos inválidos',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'No autorizado - Inicia sesión nuevamente',
        };
      } else if (response.statusCode == 422) {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error de validación',
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

  // Get all products
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.get(
        Uri.parse('$_baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'message': 'Productos obtenidos exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error al obtener productos',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Update product
  static Future<Map<String, dynamic>> updateProduct({
    required String id,
    required String name,
    required String barcode,
    required bool isBulk,
    required double weight,
    required int units,
    required double buyingPrice,
    required double sellingPrice,
    required double bulkPrice,
    required bool hasWholesalePrice,
    required double wholesalePrice,
  }) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.put(
        Uri.parse('$_baseUrl/products/$id'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'barcode': barcode,
          'isBulk': isBulk,
          'weight': weight,
          'units': units,
          'buyingPrice': buyingPrice,
          'sellingPrice': sellingPrice,
          'bulkPrice': bulkPrice,
          'hasWholesalePrice': hasWholesalePrice,
          'wholesalePrice': wholesalePrice,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        
        return {
          'success': true,
          'message': 'Producto actualizado exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error al actualizar producto',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: ${e.toString()}',
      };
    }
  }

  // Delete product
  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/products/$id'),
        headers: headers,
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
          'message': 'Producto eliminado exitosamente',
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error al eliminar producto',
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
