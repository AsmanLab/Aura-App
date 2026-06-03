import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/award/presentation/bloc/award_cubit.dart';
import '../../features/award/presentation/pages/award_page.dart';
import '../../features/duty/presentation/bloc/duty_cubit.dart';
import '../../features/duty/presentation/pages/duty_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/knowledge/presentation/pages/article_page.dart';
import '../../features/knowledge/presentation/pages/knowledge_page.dart';
import '../../features/leaderboard/presentation/bloc/leaderboard_cubit.dart';
import '../../features/leaderboard/presentation/pages/leaderboard_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shell/presentation/pages/app_shell.dart';
import '../di/injection.dart';

/// The spec "Aura" app, mounted under /aura/* alongside the existing Firebase
/// app. See commands/02_architecture.md (Navigation).
List<RouteBase> auraRoutes() => [
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => AppShell(shell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/aura/home',
            builder: (context, state) => const HomePage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/aura/leaderboard',
            builder: (context, state) => BlocProvider(
              create: (_) => LeaderboardCubit(sl()),
              child: const LeaderboardPage(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/aura/duty',
            builder: (context, state) => BlocProvider(
              create: (_) => DutyCubit(sl()),
              child: const DutyPage(),
            ),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/aura/knowledge',
            builder: (context, state) => const KnowledgePage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: '/aura/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  ),

  // Pushed routes (cover the tab bar).
  GoRoute(
    path: '/aura/profile/:id',
    builder: (context, state) =>
        ProfilePage(id: state.pathParameters['id']),
  ),
  GoRoute(
    path: '/aura/knowledge/article/:id',
    builder: (context, state) =>
        ArticlePage(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: '/aura/award',
    pageBuilder: (context, state) => _slideUp(
      state,
      BlocProvider(
        create: (_) => AwardCubit(
          sl(),
          presetInternId: state.uri.queryParameters['internId'],
        ),
        child: const AwardPage(),
      ),
    ),
  ),
  GoRoute(
    path: '/aura/settings',
    pageBuilder: (context, state) => _slideRight(state, const SettingsPage()),
  ),
];

CustomTransitionPage _slideUp(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );

CustomTransitionPage _slideRight(GoRouterState state, Widget child) =>
    CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
        position: Tween(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
