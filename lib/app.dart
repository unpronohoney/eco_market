import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco_market/core/theme/app_theme.dart';
import 'package:eco_market/core/providers/auth_provider.dart';
import 'package:eco_market/features/auth/presentation/screens/splash_screen.dart';
import 'package:eco_market/features/auth/presentation/screens/welcome_screen.dart';
import 'package:eco_market/features/main/presentation/screens/main_screen.dart';

/// Root application widget
/// Configures MaterialApp with theme and routes
class EcoMarketApp extends ConsumerWidget {
  const EcoMarketApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'EcoMarket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const _AppRouter(),
    );
  }
}

/// Smart router that determines initial screen based on auth state
class _AppRouter extends ConsumerStatefulWidget {
  const _AppRouter();

  @override
  ConsumerState<_AppRouter> createState() => _AppRouterState();
}

class _AppRouterState extends ConsumerState<_AppRouter> {
  bool _showingSplash = true;

  @override
  void initState() {
    super.initState();
    // Show splash for 2 seconds then navigate
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showingSplash = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Always show splash first
    if (_showingSplash) {
      return const SplashScreen();
    }

    // After splash, determine which screen to show
    if (authState.isLoggedIn) {
      // User is logged in, go directly to main
      return const MainScreen();
    } else if (authState.hasSeenOnboarding) {
      // User has completed onboarding, show welcome
      return const WelcomeScreen();
    } else {
      // First time user, show onboarding (via splash navigation)
      return const SplashScreen();
    }
  }
}
