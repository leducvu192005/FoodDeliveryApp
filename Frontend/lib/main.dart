import 'package:flutter/material.dart';
import 'routes/app_routers.dart';
import 'screen/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Food Delivery",
      routes: AppRoutes.routes,
      home: const LoginScreen(),
    );
  }
}
