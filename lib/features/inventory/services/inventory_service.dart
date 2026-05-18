import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pv26/core/network/api_helper.dart';
import 'package:http/http.dart' as http;


class InventoryService {
  // Create product using ApiHelper (handles refresh)
  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required String barcode,
    required bool isBulk,
    required double weight,
    required String category,
    required double units,
    required double buyingPrice,
    required double sellingPrice,
    required double bulkPrice,
    required bool hasWholesalePrice,
    required double wholesalePrice,
    required int wholesaleMinUnits,
    required bool isPackage,
    List<Map<String, dynamic>>? packageContents,
    String? locationId,
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
          'isPackage': isPackage,
          'location': locationId,
         
          if (packageContents != null && packageContents.isNotEmpty)
            'packageContents': packageContents,

           
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
  static Future<Map<String, dynamic>> getProducts(
    String? locationId,
  ) async {
    try {
      
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/products/location/$locationId',
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


  static Future<Map<String, dynamic>> getFirstProducts() async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/products/search?page=1&limit=20',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Producto obtenido exitosamente',
          'data': responseData,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error al obtener producto',
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
    required double units,
    required double buyingPrice,
    required double sellingPrice,
    required double bulkPrice,
    required bool hasWholesalePrice,
    required double wholesalePrice,
    required int wholesaleMinUnits,
    List<Map<String, dynamic>>? packageContents,

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
          if (packageContents != null && packageContents.isNotEmpty)
            'packageContents': packageContents,
          

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




  static Future<Map<String, dynamic>> importProductsFromFile({
  File? file,
  Uint8List? bytes,
  String? filename,
  required String locationId,
  required String masterId,
}) async {
  try {

    http.Response response;



  
    if (kIsWeb) {

      if (bytes == null || filename == null) {
        return {
          'success': false,
          'message': 'Archivo inválido en web',
        };
      }

      response = await ApiHelper.requestMultipartWebFileSafe(
        path: '/products/import-from-creator/$locationId',
        bytes: bytes,
        filename: filename,
        fileField: 'file',
        fields: {
          'masterId': masterId,
        },
      );
    }

    //MOBILE
    else {

      if (file == null) {
        return {
          'success': false,
          'message': 'Archivo inválido en mobile',
        };
      }

      response = await ApiHelper.requestMultipartFileSafe(
        path: '/products/import-from-creator/$locationId',
        file: file,
        fileField: 'file',
        fields: {
          'masterId': masterId,
        },
      );
    }

    
    dynamic data;

    try {
      data = jsonDecode(response.body);
    } catch (_) {
      return {
        'success': false,
        'message': 'Respuesta inválida del servidor',
        'raw': response.body,
      };
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return {
        'success': true,
        'message': data['message'] ?? 'Importación exitosa',
        'data': data,
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Error al importar productos',
    };

  } catch (e) {
    return {
      'success': false,
      'message': e.toString(),
    };
  }
}


  static Future<Map<String, dynamic>> downloadProductsExcel({
    required String locationId,
  }) async {
    try {

     

      final response = await ApiHelper.request(
        method: 'GET',
        path: '/products/export/$locationId',
      );

      
      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        return {
          'success': true,
          'message': 'Archivo descargado exitosamente',
          'bytes': bytes,
          'filename': 'products.xlsx',
        };
      } else {
        String message = 'Error al descargar archivo';

        try {
          final error = response.body.isNotEmpty
              ? response.body
              : null;
          if (error != null) {
            message = error;
          }
        } catch (_) {}

        return {
          'success': false,
          'message': message,
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



