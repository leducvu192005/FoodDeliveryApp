import '../models/shipper/driver_earnings.dart';
import '../models/shipper/driver_order.dart';
import '../models/shipper/driver_profile.dart';
import 'shipper_api_client.dart';

class ShipperDriverService {
  ShipperDriverService(this._apiClient);

  final ShipperApiClient _apiClient;

  Future<DriverProfile> getProfile(String token) async {
    final data = await _apiClient.get('/shipper/profile', token: token);
    return DriverProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<void> goOnline(String token) async {
    await _apiClient.post('/shipper/go-online', token: token);
  }

  Future<void> goOffline(String token) async {
    await _apiClient.post('/shipper/go-offline', token: token);
  }

  Future<void> updateLocation(String token, double lat, double lng) async {
    await _apiClient.post(
      '/shipper/location-update',
      token: token,
      body: {'lat': lat, 'lng': lng},
    );
  }

  Future<DriverEarnings> getTodayEarnings(String token) async {
    final data = await _apiClient.get('/shipper/earnings/today', token: token);
    return DriverEarnings.fromJson(data as Map<String, dynamic>);
  }

  Future<List<DriverOrder>> getAvailableOrders(String token) async {
    final data = await _apiClient.get('/orders/available', token: token);
    return (data as List<dynamic>)
        .map((item) => DriverOrder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DriverOrder?> getCurrentOrder(String token) async {
    final data = await _apiClient.get('/orders/current', token: token);
    final payload = data as Map<String, dynamic>;
    if (payload['order'] == null) return null;
    return DriverOrder.fromJson(payload['order'] as Map<String, dynamic>);
  }

  Future<List<DriverOrder>> getOrderHistory(String token) async {
    final data = await _apiClient.get('/orders/history', token: token);
    final payload = data as Map<String, dynamic>;
    return (payload['orders'] as List<dynamic>)
        .map((item) => DriverOrder.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<DriverOrder> acceptOrder(String token, String orderId) async {
    final data = await _apiClient.post('/orders/$orderId/accept', token: token);
    return DriverOrder.fromJson(data as Map<String, dynamic>);
  }

  Future<void> rejectOrder(String token, String orderId) async {
    await _apiClient.post('/orders/$orderId/reject', token: token);
  }

  Future<DriverOrder> pickupOrder(String token, String orderId) async {
    final data = await _apiClient.post('/orders/$orderId/pickup', token: token);
    return DriverOrder.fromJson(data as Map<String, dynamic>);
  }

  Future<DriverOrder> deliverOrder(String token, String orderId) async {
    final data =
        await _apiClient.post('/orders/$orderId/deliver', token: token);
    return DriverOrder.fromJson(data as Map<String, dynamic>);
  }
}
