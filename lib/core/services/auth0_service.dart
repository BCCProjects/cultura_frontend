import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final FlutterAppAuth _appAuth = FlutterAppAuth();
final _storage = FlutterSecureStorage();

const String AUTH0_DOMAIN = 'dev-n8fno2i64s77ybi1.us.auth0.com';
const String AUTH0_CLIENT_ID = 'pxVUM31u8kEggsqn5RcBuH20eFeKeAKg';
const String AUTH0_REDIRECT_URI = 'br.unisagrado.cultura://login-callback';
const String AUTH0_ISSUER = 'https://dev-n8fno2i64s77ybi1.us.auth0.com';


Future<String?> loginWithAuth0() async {
  try {
    final result = await _appAuth.authorizeAndExchangeCode(
      AuthorizationTokenRequest(
        AUTH0_CLIENT_ID,
        AUTH0_REDIRECT_URI,
        issuer: AUTH0_ISSUER,
        scopes: ['openid', 'profile', 'email'],
      ),
    );

    final accessToken = result?.accessToken;

    if (accessToken != null) {
      await _storage.write(key: 'jwt_token', value: accessToken);
      return accessToken;
    }

    return null;
  } catch (e) {
    print('Erro login Auth0: $e');
    return null;
  }
}
