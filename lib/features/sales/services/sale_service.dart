import 'dart:convert';
import 'package:pv26/core/network/api_helper.dart';

class SaleService {
  // Create sale with automatic token refresh
  static Future<Map<String, dynamic>> createSale({
    required List<Map<String, dynamic>> products,
    String? paymentMethod,
    double? discount,
    required String locationId, 
  }) async {
    try {

      DateTime ahora = DateTime.now();

      final response = await ApiHelper.request(
        method: 'POST',
        path: '/sale',
        body: {
          'products': products,
          'locationId': locationId,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (discount != null) 'discount': discount,
          'date': ahora.toString()
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': 'Venta creada exitosamente',
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al crear la venta: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al crear la venta: $e'};
    }
  }

  // Get recent sales
  static Future<Map<String, dynamic>> getSales() async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/sale',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'data': responseData,
        };
      } else {
        return {
          'success': false,
          'message': 'Error al obtener ventas: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al obtener ventas: $e'};
    }
  }

  // Cancel/Void a sale
  static Future<Map<String, dynamic>> cancelSale(String saleId) async {
    try {
      final response = await ApiHelper.request(
        method: 'DELETE',
        path: '/sale/$saleId',
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Venta cancelada exitosamente',
        };
      } else {
        return {
          'success': false,
          'message': 'Error al cancelar la venta: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error al cancelar la venta: $e'};
    }
  }
}
