import 'package:snapgrub/app/bootstrap/bootstrap.dart';
import 'package:snapgrub/app/env/app_config.dart';

Future<void> main() => bootstrap(AppConfig.fromEnvironment());
