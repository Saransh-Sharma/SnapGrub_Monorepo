class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.e2eEnabled,
    required this.e2eBackend,
    required this.e2eAuth,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      environment: String.fromEnvironment('SNAPGRUB_ENV', defaultValue: 'dev'),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      e2eEnabled: bool.fromEnvironment('SNAPGRUB_E2E', defaultValue: false),
      e2eBackend:
          String.fromEnvironment('SNAPGRUB_E2E_BACKEND', defaultValue: ''),
      e2eAuth: String.fromEnvironment('SNAPGRUB_E2E_AUTH', defaultValue: ''),
    );
  }

  final String environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final bool e2eEnabled;
  final String e2eBackend;
  final String e2eAuth;

  bool get hasSupabaseConfig =>
      supabaseUrl.startsWith('http') && supabaseAnonKey.isNotEmpty;

  bool get isDev => environment == 'dev';
  bool get isE2e => e2eEnabled;
  bool get isE2eMock => e2eEnabled && e2eBackend == 'mock';
  bool get isE2eSupabase => e2eEnabled && e2eBackend == 'supabase';
  bool get usesE2ePasswordAuth => e2eEnabled && e2eAuth == 'password';
}
