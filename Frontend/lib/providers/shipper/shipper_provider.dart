import 'package:flutter/foundation.dart';

import '../../models/shipper/driver_earnings.dart';
import '../../models/shipper/driver_order.dart';
import '../../models/shipper/driver_profile.dart';
import '../../services/jwt_storage_service.dart';
import '../../services/shipper_driver_service.dart';

class ShipperProvider extends ChangeNotifier {
  ShipperProvider(this._service);

  final ShipperDriverService _service;

  DriverProfile? profile;
  DriverEarnings? earnings;
  DriverOrder? currentOrder;
  List<DriverOrder> availableOrders = <DriverOrder>[];
  List<DriverOrder> historyOrders = <DriverOrder>[];

  bool isLoading = false;
  String? error;

  String _token = '';

  double acceptanceRate = 96.0;
  double cancellationRate = 1.5;
  int onlineMinutes = 0;
  double totalDistanceKm = 0;

  Future<bool> restoreSession() async {
    final token = await JwtStorageService.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    _token = token;
    await refreshAll();
    return true;
  }

  void setToken(String token) {
    _token = token;
  }

  Future<void> refreshAll() async {
    await _run(() async {
      await Future.wait([
        _loadProfile(),
        _loadEarnings(),
        _loadCurrentOrder(),
        _loadAvailableOrders(),
        _loadHistory(),
      ]);
      _deriveStats();
    });
  }

  Future<void> goOnline(bool online) async {
    await _run(() async {
      if (online) {
        await _service.goOnline(_token);
      } else {
        await _service.goOffline(_token);
      }
      await _loadProfile();
      await _loadAvailableOrders();
    });
  }

  Future<void> updateLocation(double lat, double lng) async {
    await _run(() async {
      await _service.updateLocation(_token, lat, lng);
      await _loadProfile();
    });
  }

  Future<void> acceptOrder(String orderId) async {
    await _run(() async {
      currentOrder = await _service.acceptOrder(_token, orderId);
      await _loadAvailableOrders();
      _deriveStats();
    });
  }

  Future<void> rejectOrder(String orderId) async {
    await _run(() async {
      await _service.rejectOrder(_token, orderId);
      await _loadAvailableOrders();
      _deriveStats();
    });
  }

  Future<void> markPickedUp(String orderId) async {
    await _run(() async {
      currentOrder = await _service.pickupOrder(_token, orderId);
      _deriveStats();
    });
  }

  Future<void> markDelivered(String orderId) async {
    await _run(() async {
      currentOrder = await _service.deliverOrder(_token, orderId);
      await _loadCurrentOrder();
      await _loadEarnings();
      await _loadHistory();
      _deriveStats();
    });
  }

  Future<void> _loadProfile() async {
    profile = await _service.getProfile(_token);
  }

  Future<void> _loadEarnings() async {
    earnings = await _service.getTodayEarnings(_token);
  }

  Future<void> _loadCurrentOrder() async {
    currentOrder = await _service.getCurrentOrder(_token);
  }

  Future<void> _loadAvailableOrders() async {
    availableOrders = await _service.getAvailableOrders(_token);
  }

  Future<void> _loadHistory() async {
    historyOrders = await _service.getOrderHistory(_token);
  }

  Future<void> _run(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _deriveStats() {
    final delivered =
        historyOrders.where((o) => o.status == 'completed').length;
    final cancelled =
        historyOrders.where((o) => o.status == 'cancelled').length;
    final totalDecisions = delivered + cancelled;
    if (totalDecisions > 0) {
      acceptanceRate = (delivered / totalDecisions) * 100;
      cancellationRate = (cancelled / totalDecisions) * 100;
    }

    if (profile?.isOnline == true) {
      onlineMinutes += 5;
    }

    totalDistanceKm = delivered * 2.4;
  }
}
