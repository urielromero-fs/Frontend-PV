

import 'dart:convert'; 
import 'package:pv26/core/network/api_helper.dart';
import 'dart:typed_data';
import 'dart:js_util' as js_util; 

class ReportsService {

   
    //Get report 
    static Future<Map<String, dynamic>> getReport({
      required String period,
      String? branchId,
      DateTime? date,
    })async {

      try{

         DateTime fechaConsulta = date ?? DateTime.now();

  

        final response = await ApiHelper.request(
          method: 'POST', 
          path: '/reports', 
          body: {
            'date': fechaConsulta.toIso8601String().split('T')[0], 
            'period': period,
            if (branchId != null) 'branchId': branchId,
          }
        ); 


       

        if(response.statusCode == 200 || response.statusCode == 201){

          final responseData = jsonDecode(response.body);

          return {
            'success': true, 
            'message': 'Reporte obtenido correctamente', 
            'data': responseData
          }; 
        }else{
          final errorData = jsonDecode(response.body); 

          return {
            'success': false, 
            'message': errorData['message'] ?? "Error en el servidor" 
          }; 

        }

      }catch(e){
        return {
          'success': false, 
          'message': 'Error de conexión: ${e.toString()}'
        }; 
      }





    }


    //Download excel
     static Future<Map<String, dynamic>> downloadSalesExcel() async {
      try {
        final response = await ApiHelper.request(
          method: 'GET',
          path: '/reports/download-excel/',
        
        );

        if (response.statusCode == 200) {
          // El contenido del Excel viene como bytes
          Uint8List bytes = response.bodyBytes;

             // Crear Blob
        final blob = js_util.callConstructor(
          js_util.getProperty(js_util.globalThis, 'Blob'),
          [
            [bytes],
            {"type": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"}
          ],
        );

        // Crear URL
        final url = js_util.callMethod(js_util.getProperty(js_util.globalThis, 'URL'), 'createObjectURL', [blob]);

        // Crear <a> con document.createElement('a')
        final document = js_util.getProperty(js_util.globalThis, 'document');
        final anchor = js_util.callMethod(document, 'createElement', ['a']);

        // Asignar atributos
        js_util.setProperty(anchor, 'href', url);
        js_util.setProperty(anchor, 'download', 'ventas_historico.xlsx');

        // Disparar click
        js_util.callMethod(anchor, 'click', []);

        // Revocar URL
        js_util.callMethod(js_util.getProperty(js_util.globalThis, 'URL'), 'revokeObjectURL', [url]);


          return {
            'success': true,
            'message': 'Archivo descargado correctamente',
            //'filePath': filePath,
          };
        } else {
          return {
            'success': false,
            'message': 'Error descargando archivo: ${response.statusCode}'
          };
        }
      } catch (e) {
        return {
          'success': false,
          'message': 'Error de conexión: ${e.toString()}'
        };
      }
    }












    //Get branches
    static Future<Map<String, dynamic>> getBranches() async {
      try {
        final response = await ApiHelper.request(
          method: 'GET',
          path: '/branches',
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
            'message': 'Error al cargar sucursales: ${response.statusCode}',
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
