import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'routes/app_routers.dart';
import 'screen/login_screen.dart';

const String _stripePublishableKey = String.fromEnvironment(
  'STRIPE_PUBLISHABLE_KEY',
  defaultValue: '',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_stripePublishableKey.isEmpty) {
    throw Exception(
      'Missing STRIPE_PUBLISHABLE_KEY. Run with --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_xxx',
    );
  }

  Stripe.publishableKey = _stripePublishableKey;
  await Stripe.instance.applySettings();

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
      title: 'Food Delivery',
      routes: AppRoutes.routes,
      home: const LoginScreen(),
    );
  }
}
