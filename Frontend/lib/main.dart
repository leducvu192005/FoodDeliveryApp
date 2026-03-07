import 'package:flutter/material.dart';
import 'package:flutter_application_1/providers/auth_provider.dart';
import 'package:flutter_application_1/providers/favorite_provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_config.dart';
import 'routes/app_routers.dart';
import 'screen/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ApiConfig.init();

  // Stripe key: DEV dùng fallback, PROD truyền qua --dart-define
  const stripeKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue:
        'pk_test_51SzzRqFk1s2i0vMsjdJUZWcGBALXKMMFTy7E9a5M5q1gr0O38jc9UlOuVt2yy34UDiCxWxjjk32t2X5ehrTsl1aA00GQzxTYW2',
  );

  Stripe.publishableKey = stripeKey;
  await Stripe.instance.applySettings();

  await Supabase.initialize(
    url: 'https://pwwkqdizdbxvgpbysfgy.supabase.co',
    anonKey: 'sb_publishable_rsoTTaoxacfdZeeAH--oHQ_Jwp1a8Dr',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Food Delivery',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFAF0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE67E22),
          primary: const Color(0xFFE67E22),
          secondary: const Color(0xFFFFB347),
          surface: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFAF0),
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      routes: AppRoutes.routes,
      home: const LoginScreen(),
    );
  }
}
