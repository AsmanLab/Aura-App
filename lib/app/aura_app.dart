import 'package:aura_app/features/auth/presentation/auth_providers.dart';
import 'package:aura_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:aura_app/features/auth/presentation/pages/login_screen.dart';
import 'package:aura_app/features/auth/presentation/pages/splash_screen.dart';
import 'package:aura_app/core/theme/app_theme.dart';
import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/router/app_router.dart';
import 'package:aura_app/core/router/navigation.dart';
import 'package:aura_app/core/settings/locale_cubit.dart';
import 'package:aura_app/core/settings/theme_cubit.dart';
import 'package:aura_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:aura_app/core/services/app_update_service.dart';
import 'package:aura_app/features/attendance/presentation/bloc/attendance_cubit.dart';
import 'package:aura_app/features/attendance/domain/repositories/attendance_repository.dart';
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
  late final ValueNotifier<AsyncValue<bool>> _auth = ValueNotifier(ref.read(authStateProvider));
  late final GoRouter _router = _createRouter();

  @override
  void dispose() {
    _router.dispose();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(authStateProvider, (prev, next) {
      _auth.value = next;
      // Trigger update check once on sign-in (cold start only).
      next.whenData((isAuthed) {
        final wasAuthed = prev?.value ?? false;
        if (isAuthed && !wasAuthed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              sl<AppUpdateService>().checkAndPrompt(context);
            }
          });
        }
      });
    });

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: sl<ThemeCubit>()),
        BlocProvider.value(value: sl<LocaleCubit>()),
        BlocProvider(
          create: (_) => AttendanceCubit(
            sl<AttendanceRepository>(),
            sl<AuthRepository>().currentUser?.id ?? '',
          ),
        ),
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
      navigatorKey: rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: _auth,
      redirect: (context, state) {
        final authState = _auth.value;
        final path = state.uri.toString();
        final isPublic = path == '/login' ||
            path == '/splash' ||
            path == '/style-gallery';
        return authState.when(
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
