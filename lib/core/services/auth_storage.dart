import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// core/services/auth_storage.dart
class AuthStorage {
  static const _accessKey  = 'jwt_access';
  static const _refreshKey = 'jwt_refresh';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveAccess(String token) =>
      _storage.write(key: _accessKey, value: token);
  static Future<void> saveRefresh(String token) =>
      _storage.write(key: _refreshKey, value: token);

  static Future<String?> readAccess()  =>
      _storage.read(key: _accessKey);
  static Future<String?> readRefresh() =>
      _storage.read(key: _refreshKey);

  static Future<void> clear() => Future.wait([
    _storage.delete(key: _accessKey),
    _storage.delete(key: _refreshKey),
  ]);
}
