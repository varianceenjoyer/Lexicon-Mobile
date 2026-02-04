import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/service_providers.dart';
import 'services/lexicon_flutter_service.dart';

/// Root application widget for Lexicon Mobile.
///
/// Configures Material 3 theming and GoRouter navigation.
/// Shows a loading screen while the STT model preloads.
/// Handles memory pressure to clear model cache when OS signals low memory.
class LexiconApp extends ConsumerStatefulWidget {
  const LexiconApp({super.key});

  @override
  ConsumerState<LexiconApp> createState() => _LexiconAppState();
}

class _LexiconAppState extends ConsumerState<LexiconApp>
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
  void didHaveMemoryPressure() {
    // Clear model cache when OS signals low memory
    LexiconFlutterService.handleMemoryPressure();
  }

  @override
  Widget build(BuildContext context) {
    final modelPreload = ref.watch(modelPreloadProvider);

    return MaterialApp(
      title: 'Lexicon',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: modelPreload.when(
        data: (_) => const _LoadedApp(),
        loading: () => const _LoadingScreen(),
        error: (_, __) => const _LoadedApp(), // Continue anyway on error
      ),
    );
  }
}

/// The main app with router, shown after model is loaded.
class _LoadedApp extends ConsumerWidget {
  const _LoadedApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Lexicon',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Loading screen shown while STT model preloads.
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/logo placeholder
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.mic,
                size: 40,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 32),
            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            // Loading text
            Text(
              'Loading speech model...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
