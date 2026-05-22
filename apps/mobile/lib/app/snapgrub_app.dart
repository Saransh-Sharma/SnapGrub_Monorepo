import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapgrub/app/env/app_config.dart';
import 'package:snapgrub/app/env/app_config_provider.dart';
import 'package:snapgrub/app/router/app_router.dart';
import 'package:snapgrub/app/theme/app_theme.dart';
import 'package:snapgrub/features/auth/application/auth_controller.dart';
import 'package:snapgrub/features/auth/domain/auth_state.dart';
import 'package:snapgrub/offline/sync/sync_controller.dart';

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

class _SnapGrubAppView extends ConsumerStatefulWidget {
  const _SnapGrubAppView();

  @override
  ConsumerState<_SnapGrubAppView> createState() => _SnapGrubAppViewState();
}

class _SnapGrubAppViewState extends ConsumerState<_SnapGrubAppView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref
          .read(syncControllerProvider.notifier)
          .syncNow(trigger: SyncTrigger.foreground);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (_, next) {
      final auth = next.valueOrNull;
      if (auth?.status == AuthStatus.signedIn) {
        ref
            .read(syncControllerProvider.notifier)
            .syncNow(trigger: SyncTrigger.login);
      }
    });
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'SnapGrub',
      theme: buildSnapGrubTheme(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
