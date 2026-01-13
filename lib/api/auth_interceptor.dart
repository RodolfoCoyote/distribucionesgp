import 'dart:async';
import 'package:chopper/chopper.dart';
import 'package:distribucionesgp/utils/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor implements RequestInterceptor {
  final _storage = const FlutterSecureStorage();

  @override
  FutureOr<Request> onRequest(Request request) async {
    // 1. Si la petición es para el login, no busques el token
    if (request.url.toString().contains('auth/inicio_empleado')) {
      final Map<String, String> authHeaders = Map<String, String>.from(
        request.headers,
      );
      final String jwtMaster = AppConstants.jwtMaster;
      authHeaders['data-jwt-master'] = jwtMaster;
      return request.copyWith(headers: authHeaders);
    }

    // 2. Para todo lo demás, busca el token
    final token = await _storage.read(key: 'auth_token');

    if (token != null && token.isNotEmpty) {
      final updatedHeaders = Map<String, String>.from(request.headers);
      updatedHeaders['data-jwt-user'] = token;
      return request.copyWith(headers: updatedHeaders);
    }

    return request;
  }
}
