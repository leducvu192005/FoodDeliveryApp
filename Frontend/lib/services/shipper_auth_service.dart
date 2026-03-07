import '../models/shipper/auth_session.dart';
import 'jwt_storage_service.dart';
import 'shipper_api_client.dart';

class ShipperAuthService {
  ShipperAuthService(this._apiClient);

  final ShipperApiClient _apiClient;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final data = await _apiClient.post(
      '/auth/login',
      body: {
        'email': email,
        'password': password,
      },
    );

    final session = AuthSession.fromJson(data as Map<String, dynamic>);
    await JwtStorageService.saveToken(session.accessToken);
    return session;
  }

  Future<void> logout() {
    return JwtStorageService.clear();
  }
}
