import 'package:flutter/widgets.dart';
import 'package:snapgrub/app/env/app_config.dart';
import 'package:snapgrub/app/snapgrub_app.dart';
import 'package:snapgrub/core/design_system/effects/shader_library.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;

Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  // Compile GPU effects while the splash plays; never block startup on it.
  ShaderLibrary.preloadAll();

  if (config.hasSupabaseConfig) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
    );
  }

  runApp(SnapGrubApp(config: config));
}
