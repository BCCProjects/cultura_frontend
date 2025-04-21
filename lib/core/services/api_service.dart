import 'package:dio/dio.dart';
import '../config.dart';

class ApiService {
  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(BaseOptions(baseUrl: kBaseUrl));
  }

  static final ApiService instance = ApiService._internal();
  Dio get client => _dio;

  void setToken(String? token) {
    _dio.interceptors.clear();
    if (token != null && token.isNotEmpty) {
      _dio.interceptors.add(
        InterceptorsWrapper(onRequest: (options, handler) {
          options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        }),
      );
    }
  }
}
