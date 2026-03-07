class AppConstants {
  const AppConstants._();

  static const String appTitle = 'Food Delivery - Shipper';
  static const String demoShipperId = '10000000-0000-0000-0000-000000000001';

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://pwwkqdizdbxvgpbysfgy.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_rsoTTaoxacfdZeeAH--oHQ_Jwp1a8Dr',
  );
}
