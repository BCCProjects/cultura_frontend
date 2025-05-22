import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config.dart';
import '../../providers/auth_provider.dart';

class ApiService {
  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(baseUrl: kBaseUrl));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioError err, ErrorInterceptorHandler handler) {
          if (err.response?.statusCode == 401) {
            _handleUnauthorized();
          }
          return handler.next(err);
        },
      ),
    );
  }

  static final ApiService instance = ApiService._internal();
  Dio get client => _dio;

  void setToken(String? token) {
    _dio.interceptors.removeWhere((i) => i is _TokenInterceptor);
    if (token != null && token.isNotEmpty) {
      _dio.interceptors.add(_TokenInterceptor(token));
    }
  }

  void _handleUnauthorized() {
    final container = ProviderContainer();

    container.read(authProvider.notifier).logout();

    final context = navigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sessão expirada. Faça login novamente.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    navigatorKey.currentState?.pushNamedAndRemoveUntil('/login', (_) => false);
  }
}

class _TokenInterceptor extends Interceptor {
  final String token;
  _TokenInterceptor(this.token);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $token';
    handler.next(options);
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
