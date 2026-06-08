import 'package:aura_app/features/auth/presentation/auth_providers.dart';
import 'package:aura_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:aura_app/features/auth/presentation/pages/login_screen.dart';
import 'package:aura_app/features/auth/presentation/pages/splash_screen.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/router/app_router.dart';
import 'package:aura_app/core/settings/locale_cubit.dart';
import 'package:aura_app/core/settings/theme_cubit.dart';
import 'package:aura_app/features/profile/presentation/pages/style_gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AuraApp extends ConsumerStatefulWidget {
  const AuraApp({super.key});

  @override
  ConsumerState<AuraApp> createState() => _AuraAppState();
}

class _AuraAppState extends ConsumerState<AuraApp> {
  // Latest auth state, exposed to the router as a refresh trigger. The router
  // is built ONCE; this notifier re-runs its redirect on auth changes instead
  // of recreating the router (which deactivates widgets mid-flight).
  late final ValueNotifier<AsyncValue<bool>> _auth =
      ValueNotifier(ref.read(authStateProvider));
  late final GoRouter _router = _createRouter();

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Push auth changes into the notifier → router redirect re-runs.
    ref.listen<AsyncValue<bool>>(authStateProvider, (_, next) {
      _auth.value = next;
    });

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
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            routerConfig: _router,
          );
        },
      ),
    );
  }

  GoRouter _createRouter() {
    return GoRouter(
      // Boot to '/splash' while the persisted session is validated; redirect
      // then routes to the app ('/aura/home') or '/login'.
      initialLocation: '/splash',
      refreshListenable: _auth,
      redirect: (context, state) {
        final authState = _auth.value;
        final path = state.uri.toString();
        // Auth-free routes. The app ('/aura/*') now requires a session.
        final isPublic = path == '/login' ||
            path == '/splash' ||
            path == '/style-gallery';
        return authState.when(
          // Auth resolved: leave the splash for the right destination.
          data: (isAuthenticated) {
            if (path == '/splash') {
              return isAuthenticated ? '/aura/home' : '/login';
            }
            if (!isAuthenticated && !isPublic) {
              return '/login';
            }
            if (isAuthenticated && path == '/login') {
              return '/aura/home';
            }
            return null;
          },
          // Still resolving: hold on the splash.
          loading: () => path == '/splash' ? null : '/splash',
          error: (_, __) => isPublic ? null : '/login',
        );
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const SplashScreen(),
        ),
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
        // The Aura app (auth-gated), mounted at /aura/*.
        ...auraRoutes(),
      ],
    );
  }
}
