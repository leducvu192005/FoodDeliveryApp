import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;

  String? get token => _token;

  void setToken(String token) {
    _token = token;
    notifyListeners();
  }

  void logout() {
    _token = null;
    notifyListeners();
  }

  bool get isLoggedIn => _token != null;
}
