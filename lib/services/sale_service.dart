import 'dart:convert';
import 'api_helper.dart';

class SaleService {
  // Create sale with automatic token refresh
  static Future<Map<String, dynamic>> createSale({
    required List<Map<String, dynamic>> products,
    String? paymentMethod,
    double? discount,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'POST',
        path: '/sale',
        body: {
          'products': products,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
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
}
