import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/api_service.dart';
import '../core/services/auth_storage.dart';
import '../core/config.dart';

class AuthState {
  final String? token;
  final bool loading;
  const AuthState({this.token, this.loading = false});
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final t = await AuthStorage.read();
    ApiService.instance.setToken(t);
    state = AuthState(token: t);
  }

  Future<void> login(String user, String pass) async {
    state = const AuthState(loading: true);
    final r = await ApiService.instance.client
        .post(kApiToken, data: {'username': user, 'password': pass});
    final t = r.data['access'] as String;
    await AuthStorage.save(t);
    ApiService.instance.setToken(t);
    state = AuthState(token: t);
  }

  Future<void> logout() async {
    await AuthStorage.clear();
    ApiService.instance.setToken(null);
    state = const AuthState();
  }
}

final authProvider =
StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
