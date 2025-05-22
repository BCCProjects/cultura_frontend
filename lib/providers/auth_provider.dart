import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_storage.dart';
import '../core/config.dart';

class AuthState {
  final String? token;
  final bool loading;

  const AuthState({this.token, this.loading = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(loading: true)) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    // Carrega o access token salvo
    final access = await AuthStorage.readAccess();
    if (access != null && access.isNotEmpty) {
      ApiService.instance.setToken(access);
      state = AuthState(token: access, loading: false);
    } else {
      state = const AuthState(loading: false);
    }
  }

  Future<void> login(String user, String pass) async {
    state = const AuthState(loading: true);
    try {
      final tempDio = Dio(BaseOptions(baseUrl: kBaseUrl));
      final r = await tempDio.post(kApiToken, data: {
        'username': user,
        'password': pass,
      });
      final access  = r.data['access'] as String;
      final refresh = r.data['refresh'] as String;

      // Salva os tokens
      await AuthStorage.saveAccess(access);
      await AuthStorage.saveRefresh(refresh);

      ApiService.instance.setToken(access);
      state = AuthState(token: access, loading: false);
    } catch (e) {
      state = const AuthState(loading: false);
      rethrow;
    }
  }

  /// Permite injetar manualmente um access token
  Future<void> setToken(String token) async {
    await AuthStorage.saveAccess(token);
    ApiService.instance.setToken(token);
    state = AuthState(token: token, loading: false);
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    ApiService.instance.setToken(null);
    state = const AuthState();
  }
}

final authProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
