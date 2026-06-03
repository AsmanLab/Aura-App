import 'package:aura_app/core/services/auth_service.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/features/screens/give_aura_screen.dart';
import 'package:aura_app/features/screens/home_screen.dart';
import 'package:aura_app/features/screens/leaderboard_screen.dart';
import 'package:aura_app/features/screens/login_screen.dart';
import 'package:aura_app/features/screens/main_shell_screen.dart';
import 'package:aura_app/features/screens/profile_screen.dart';
import 'package:aura_app/features/screens/roulette_screen.dart';
import 'package:aura_app/features/style_gallery/style_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'AuraApp',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: _createRouter(authState),
    );
  }

  GoRouter _createRouter(AsyncValue<bool> authState) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        return authState.when(
          data: (isAuthenticated) {
            if (!isAuthenticated && state.uri.toString() != '/login') {
              return '/login';
            }
            if (isAuthenticated && state.uri.toString() == '/login') {
              return '/';
            }
            return null;
          },
          loading: () => null,
          error: (_, __) => '/login',
        );
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        // Stage-1 design-token preview (debug). Remove before release.
        GoRoute(
          path: '/style-gallery',
          builder: (context, state) => const StyleGalleryScreen(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainShell(child: child),
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/leaderboard',
              builder: (context, state) => const LeaderboardScreen(),
            ),
            GoRoute(
              path: '/roulette',
              builder: (context, state) => const RouletteScreen(),
            ),
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
            GoRoute(
              path: '/give-aura',
              builder: (context, state) => const GiveAuraScreen(),
            ),
          ],
        ),
      ],
    );
  }
}