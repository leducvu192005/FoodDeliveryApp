import 'package:flutter/material.dart';
import '../screen/login_screen.dart';
import '../screen/register_screen.dart';
<<<<<<< HEAD
import '../screen/Buyer/buyer_home.dart';  
import '../screen/Buyer/profile.dart';      
import '../screen/Buyer/cart.dart';        
import '../screen/Buyer/layout.dart';       
import '../screen/Buyer/order.dart';        
import '../screen/Buyer/foodpage.dart';     
import '../screen/nav.dart';                
=======
import '../screen/Buyer/buyer_home.dart';
import '../screen/Buyer/profile.dart';
import '../screen/Buyer/cart.dart';
import '../screen/Buyer/layout.dart';
import '../screen/Buyer/order.dart';
import '../screen/seller/home/home.dart';
import '../screen/shipper/shipper_home.dart';
import '../screen/shipper/order_shipper.dart';
>>>>>>> 392c371 (làm giao diện giỏ hàng và xử lí thanh toán)

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    "/login": (_) => const LoginScreen(),
    "/register": (_) => const RegisterScreen(),
    "/buyer": (_) => const BuyerHome(),
    "/buyer/profile": (_) => const Profile(),
    "/buyer/cart": (_) => const Cart(),
    "/buyer/layout": (_) => const Layout(),
    "/buyer/order": (_) => const Order(),
    "/seller": (_) => SellerHomeScreen(),
    "/shipper": (_) => const ShipperHome(),
    "/shipper/order": (_) => const OrderShipper(),
  };
}