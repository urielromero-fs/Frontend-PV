import 'dart:convert';
import 'package:pv26/core/network/api_helper.dart';

class AttendanceService {


  // CHECK-IN
  static Future<Map<String, dynamic>> checkIn({
    required String locationId,
    required String checkInDate,
    required String userId,
  }) async {
    try {

      

      final response = await ApiHelper.request(
        method: 'POST',
        path: '/attendance/checkin/$locationId',
        body: {
         'checkInDate': checkInDate, 
         'userId': userId
        },
      );

  

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': 'Check-in exitoso',
          'data': data,
        };

      } else {
        
        return {
          'success': false,
          'message':  'Error al registrar la entrada o ya hay una entrada registrada',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  // CHECK-OUT
  static Future<Map<String, dynamic>> checkOut({
    required String locationId,
    required checkOutDate,
    required String userId,
  }) async {
    try {

     

      final response = await ApiHelper.request(
        method: 'POST',
        path: '/attendance/checkout/$locationId',
        body: {
        'checkOutDate': checkOutDate,
        'userId': userId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'message': data['message'] ?? 'Check-out exitoso',
          'data': data['attendance'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al registrar check-out',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }


  // GET ALL BY LOCATION
  static Future<Map<String, dynamic>> getAttendancesByLocation({
    required String locationId,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/attendance/location/$locationId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al obtener asistencias',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }


  // GET BY USER
  static Future<Map<String, dynamic>> getAttendanceByUser({
    required String userId,
  }) async {
    try {
      final response = await ApiHelper.request(
        method: 'GET',
        path: '/attendance/user/$userId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al obtener historial',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }


  // LAST 10 BY USER

  static Future<Map<String, dynamic>> getLast10AttendanceByUser({
    required String userId,
  }) async {
    try {

     

      final response = await ApiHelper.request(
        method: 'GET',
        path: '/attendance/last10/user/$userId',
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        return {
          'success': true,
          'data': data,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error al obtener últimos registros',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }



}