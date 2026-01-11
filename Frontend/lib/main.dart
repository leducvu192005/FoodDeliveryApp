import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'routes/app_routers.dart';
import 'screen/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Supabase
  await Supabase.initialize(
    url: 'https://pwwkqdizdbxvgpbysfgy.supabase.co',
    anonKey: 'sb_publishable_rsoTTaoxacfdZeeAH--oHQ_Jwp1a8Dr',
  );

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
