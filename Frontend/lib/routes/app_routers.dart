import 'package:flutter/material.dart';
import '../screen/login_screen.dart';
import '../screen/register_screen.dart';
import '../screen/buyer_home.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    "/login": (_) => const LoginScreen(),
    "/register": (_) => const RegisterScreen(),
    "/buyer": (_) => const BuyerHome(),
  };
}
