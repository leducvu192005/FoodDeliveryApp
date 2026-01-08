import 'package:flutter/material.dart';
import '../screen/login_screen.dart';
import '../screen/register_screen.dart';
import '../Buyer/buyer_home.dart';
import '../Buyer/profile.dart';
import '../Buyer/cart.dart';
import '../Buyer/layout.dart';
import '../Buyer/order.dart';
import '../Buyer/foodpage.dart';
import '../screen/seller/home/home.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    "/login": (_) => const LoginScreen(),
    "/register": (_) => const RegisterScreen(),
    "/buyer": (_) => const BuyerHome(),
    "/buyer/profile": (_) => const Profile(),
    "/buyer/cart": (_) => const Cart(),
    "/buyer/layout": (_) => const Layout(),
    "/buyer/order": (_) => const Order(),
    "/buyer/foodpage": (_) => const Foodpage(),
    "/seller": (_) => SellerHomeScreen(),
  };
}
