import 'package:flutter/foundation.dart';

import '../services/favorite_service.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteService _favoriteService = FavoriteService();
  final Set<int> _favoriteIds = <int>{};
  bool _isLoaded = false;
  bool _isSaving = false;

  FavoriteProvider() {
    _loadFavorites();
  }

  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  Set<int> get favoriteIds => Set<int>.unmodifiable(_favoriteIds);

  bool isFavorite(int productId) => _favoriteIds.contains(productId);

  Future<void> _loadFavorites() async {
    try {
      final ids = await _favoriteService.getFavoriteIds();
      _favoriteIds
        ..clear()
        ..addAll(ids);
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    _isLoaded = false;
    notifyListeners();
    await _loadFavorites();
  }

  Future<void> toggleFavorite(int productId) async {
    if (_isSaving) {
      return;
    }

    final wasFavorite = _favoriteIds.contains(productId);
    _isSaving = true;

    if (wasFavorite) {
      _favoriteIds.remove(productId);
    } else {
      _favoriteIds.add(productId);
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _favoriteService.removeFavorite(productId);
      } else {
        await _favoriteService.addFavorite(productId);
      }
    } catch (_) {
      if (wasFavorite) {
        _favoriteIds.add(productId);
      } else {
        _favoriteIds.remove(productId);
      }
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
