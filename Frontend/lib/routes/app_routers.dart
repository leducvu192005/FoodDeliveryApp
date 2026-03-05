import 'package:flutter/material.dart';
import '../screen/login_screen.dart';
import '../screen/register_screen.dart';
import '../screen/Buyer/buyer_home.dart';
import '../screen/Buyer/profile.dart';
import '../screen/Buyer/cart.dart';
import '../screen/Buyer/layout.dart';
import '../screen/Buyer/order.dart';
import '../screen/Buyer/favorites.dart';
// import '../screen/seller/home/home.dart';
import '../screen/nav.dart';
import '../screen/Shipper/shipper_home.dart';
import '../screen/Shipper/order_shipper.dart';
import '../screen/shipper/layout_shipper.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    "/login": (_) => const LoginScreen(),
    "/register": (_) => const RegisterScreen(),
    "/buyer": (_) => const Layout(),
    "/buyer/home": (_) => const BuyerHome(),
    "/buyer/profile": (_) => const Profile(),
    "/buyer/cart": (_) => const Cart(),
    "/buyer/layout": (_) => const Layout(),
    "/buyer/order": (_) => const Order(),
    "/buyer/favorites": (_) => const Favorites(),
    "/seller": (_) => const SellerNavScreen(),
    "/shipper": (_) => const ShipperHome(),
    "/shipper/order": (_) => const OrderShipper(),
    "/shipper/layout": (_) => const LayoutShipper(),
  };
}
