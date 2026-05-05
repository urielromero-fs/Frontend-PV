  import 'dart:convert';
  import 'package:http/http.dart' as http;
  import 'package:pv26/features/auth/services/auth_service.dart';
  import 'dart:io';
  import 'dart:typed_data';
  import 'package:http_parser/http_parser.dart';

  class ApiHelper {
    static const String _baseUrl = 'https://punto-de-venta-mu.vercel.app/api';

    static Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {

      final token = await AuthService.getAccessToken();

      final headers = <String, String>{
        'Accept': 'application/json',
        if (!isMultipart) 'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      return headers; 
    }

    static Future<http.Response> request({
      required String method,
      required String path,
      dynamic body,
    }) async {
      final url = Uri.parse('$_baseUrl$path');
      final headers = await _getHeaders();
      
      http.Response response;
      
      // Perform initial request
      response = await _executeRequest(method, url, headers, body);

      // If 401 Unauthorized, try to refresh token
      if (response.statusCode == 401) {
        final refreshResult = await AuthService.refreshAccessToken();
        
        if (refreshResult['success'] == true) {
          // Retry with new token
          final newHeaders = await _getHeaders();
          response = await _executeRequest(method, url, newHeaders, body);
        }
      }

      return response;
    }

    static Future<http.Response> _executeRequest(
      String method,
      Uri url,
      Map<String, String> headers,
      dynamic body,
    ) async {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(url, headers: headers);
        case 'POST':
          return await http.post(url, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PUT':
          return await http.put(url, headers: headers, body: body != null ? jsonEncode(body) : null);
        case 'PATCH': 
          return await http.patch(url, headers: headers, body: body != null ? jsonEncode(body) : null);

        case 'DELETE':
          return await http.delete(url, headers: headers);
        default:
          throw Exception('HTTP Method $method not supported');
      }
    }
  

   //mobile
  static Future<http.Response> requestMultipart({
    required String path,
    required File file,
    String fileField = 'logo',
    Map<String, String>? fields,
    String method = 'POST',
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _getHeaders(isMultipart: true);


    final request = http.MultipartRequest(method, url);
    request.headers.addAll(headers);

    if (fields != null) {
      request.fields.addAll(fields);
    }


    request.files.add(
      await http.MultipartFile.fromPath(fileField, file.path),
    );

    final streamed = await request.send();

    return await http.Response.fromStream(streamed);
  }

   //web
  static Future<http.Response> requestMultipartWeb({
    required String path,
    required Uint8List bytes,
    required String filename,
    String fileField = 'logo',
    Map<String, String>? fields,
    String method = 'POST',
  }) async {
    final url = Uri.parse('$_baseUrl$path');
    final headers = await _getHeaders(isMultipart: true);

    final request = http.MultipartRequest(method, url);
    request.headers.addAll(headers);

     
    if (fields != null) {
      request.fields.addAll(fields);
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        fileField,
        bytes,
        filename: filename,
        contentType: MediaType('image', 'png'),
      ),
    );

      final streamed = await request.send();

   return await http.Response.fromStream(streamed);
  }

  
  }
