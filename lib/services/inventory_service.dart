import 'dart:convert';
import 'api_helper.dart';

class InventoryService {
  // Create product using ApiHelper (handles refresh)
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String barcode,
    required bool isBulk,
    required double weight,
    required String category,
    required int units,
    required double buyingPrice,
    required double sellingPrice,
    required double bulkPrice,
    required bool hasWholesalePrice,
    required double wholesalePrice,
    required int wholesaleMinUnits,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/products',
        body: {
          'name': name,
          'barcode': barcode,
          'isBulk': isBulk,
          'weight': weight,
          'category': category,
          'units': units,
          'buyingPrice': buyingPrice,
          'sellingPrice': sellingPrice,
          'bulkPrice': bulkPrice,
          'hasWholesalePrice': hasWholesalePrice,
          'wholesalePrice': wholesalePrice,
          'wholesaleMinUnits': wholesaleMinUnits,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Producto creado exitosamente',
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

  // Get all products using ApiHelper
  static Future<Map<String, dynamic>> getProducts() async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/products',
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

  // Update product using ApiHelper
  static Future<Map<String, dynamic>> updateProduct({
    required String id,
    required String name,
    required String barcode,
    required bool isBulk,
    required double weight,
    required String category,
    required int units,
    required double buyingPrice,
    required double sellingPrice,
    required double bulkPrice,
    required bool hasWholesalePrice,
    required double wholesalePrice,
    required int wholesaleMinUnits,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'PUT',
        path: '/products/$id',
        body: {
          'name': name,
          'barcode': barcode,
          'isBulk': isBulk,
          'weight': weight,
          'category': category,
          'units': units,
          'buyingPrice': buyingPrice,
          'sellingPrice': sellingPrice,
          'bulkPrice': bulkPrice,
          'hasWholesalePrice': hasWholesalePrice,
          'wholesalePrice': wholesalePrice,
          'wholesaleMinUnits': wholesaleMinUnits,
        },
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

  // Delete product using ApiHelper
  static Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final response = await ApiHelper.request(
        method: 'DELETE',
        path: '/products/$id',
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Producto eliminado exitosamente'};
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
