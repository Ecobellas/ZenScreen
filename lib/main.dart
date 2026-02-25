import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/providers.dart';
import 'features/friction/services/friction_interceptor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        frictionNavigatorKeyProvider.overrideWithValue(rootNavigatorKey),
      ],
      child: const ZenScreenApp(),
    ),
  );
}

class ZenScreenApp extends ConsumerStatefulWidget {
  const ZenScreenApp({super.key});

  @override
  ConsumerState<ZenScreenApp> createState() => _ZenScreenAppState();
}

class _ZenScreenAppState extends ConsumerState<ZenScreenApp> {
  @override
  void initState() {
    super.initState();
    // Start the friction interceptor after the first frame so the navigator
    // key is attached.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prefs = ref.read(preferencesServiceProvider);
      if (prefs.isOnboardingComplete) {
        ref.read(frictionInterceptorProvider).start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'ZenScreen',
      theme: AppTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
