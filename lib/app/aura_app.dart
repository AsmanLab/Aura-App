import 'package:aura_app/features/auth/presentation/auth_providers.dart';
import 'package:aura_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:aura_app/features/auth/presentation/pages/login_screen.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/features/give_aura/presentation/pages/give_aura_screen.dart';
import 'package:aura_app/features/home/presentation/pages/home_screen.dart';
import 'package:aura_app/features/leaderboard/presentation/pages/leaderboard_screen.dart';
import 'package:aura_app/features/profile/presentation/pages/main_shell_screen.dart';
import 'package:aura_app/features/profile/presentation/pages/profile_screen.dart';
import 'package:aura_app/features/roulette/presentation/pages/roulette_screen.dart';
import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/router/app_router.dart';
import 'package:aura_app/features/debug/seed_debug_screen.dart';
import 'package:aura_app/core/settings/locale_cubit.dart';
import 'package:aura_app/core/settings/theme_cubit.dart';
import 'package:aura_app/features/profile/presentation/pages/style_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuraApp extends ConsumerWidget {
  const AuraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<LocaleCubit>()),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeCubit>().state;
          final locale = context.watch<LocaleCubit>().state;
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'AuraApp',
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeMode,
            locale: locale,
            supportedLocales: const [Locale('en'), Locale('ru')],
            localizationsDelegates:
                GlobalMaterialLocalizations.delegates,
            routerConfig: _createRouter(authState),
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AsyncValue<bool> authState) {
    return GoRouter(
      // Boot to '/', which redirects unauthenticated users to '/login'.
      initialLocation: '/',
      redirect: (context, state) {
        final path = state.uri.toString();
        // Spec "Aura" app + debug screens render standalone on seed data.
        final isPublic = path == '/login' ||
            path.startsWith('/aura') ||
            path == '/style-gallery' ||
            path == '/debug-seed';
        return authState.when(
          data: (isAuthenticated) {
            if (!isAuthenticated && !isPublic) {
              return '/login';
            }
            if (isAuthenticated && path == '/login') {
              return '/';
            }
            return null;
          },
          loading: () => null,
          error: (_, __) => isPublic ? null : '/login',
        );
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<AuthCubit>(),
            child: const LoginScreen(),
          ),
        ),
        // Stage-1 design-token preview (debug). Remove before release.
        GoRoute(
          path: '/style-gallery',
          builder: (context, state) => const StyleGalleryScreen(),
        ),
        // Stage-3 seed data dump (debug). Remove before release.
        GoRoute(
          path: '/debug-seed',
          builder: (context, state) => const SeedDebugScreen(),
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
        // Spec "Aura" app (Stages 4–7), mounted at /aura/*.
        ...auraRoutes(),
      ],
    );
  }
}