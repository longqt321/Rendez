import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? status;
  const ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  static const configuredUrl = String.fromEnvironment('API_BASE_URL');
  final String baseUrl;
  final http.Client _client = http.Client();
  String? token;

  ApiClient()
    : baseUrl = configuredUrl.isNotEmpty
          ? configuredUrl
          : (!kIsWeb && defaultTargetPlatform == TargetPlatform.android)
          ? 'http://10.0.2.2:8080'
          : 'http://127.0.0.1:8080';

  Future<dynamic> request(String method, String path, [Object? body]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    return _send(request);
  }

  Future<dynamic> upload(
    Map<String, String> fields,
    List<({String name, Uint8List bytes})> images,
  ) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/v1/contributions'),
    );
    request.fields.addAll(fields);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    for (final image in images) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'images',
          image.bytes,
          filename: image.name,
        ),
      );
    }
    return _send(request, timeout: const Duration(seconds: 60));
  }

  Future<dynamic> _send(
    http.BaseRequest request, {
    Duration timeout = const Duration(seconds: 40),
  }) async {
    try {
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(timeout),
      ).timeout(timeout);
      final data = response.body.isEmpty ? null : jsonDecode(response.body);
      if (response.statusCode >= 400) {
        throw ApiException(
          data?['error']?['message'] as String? ?? 'Yêu cầu thất bại',
          response.statusCode,
        );
      }
      return data;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        'Không kết nối được máy chủ. Kiểm tra kết nối mạng rồi thử lại.',
      );
    }
  }

  Future<Uint8List> image(String path) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: token == null ? {} : {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const ApiException('Không đọc được ảnh');
      }
      return response.bodyBytes;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Không kết nối được ảnh');
    }
  }

  void close() => _client.close();
}
