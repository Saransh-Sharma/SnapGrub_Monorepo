import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/env/app_config.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/app/theme/app_theme.dart';

class SnapGrubApp extends StatelessWidget {
  const SnapGrubApp({required this.config, super.key});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
      ],
      child: const _SnapGrubAppView(),
    );
  }
}

class _SnapGrubAppView extends ConsumerWidget {
  const _SnapGrubAppView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SnapGrub',
      theme: buildSnapGrubTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
