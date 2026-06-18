import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthManager {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService apiService;
  static const _tokenKey = 'jwt_token';

  AuthManager(this.apiService);

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    apiService.updateToken(token);
  }

  Future<String?> loadToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      apiService.updateToken(token);
    }
    return token;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
    apiService.updateToken('');
  }
}
