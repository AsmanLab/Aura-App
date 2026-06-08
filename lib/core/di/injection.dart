import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/award/data/datasources/award_remote_data_source.dart';
import '../../features/award/data/repositories/award_repository_impl.dart';
import '../../features/award/domain/repositories/award_repository.dart';
import '../../features/leaderboard/data/datasources/leaderboard_remote_data_source.dart';
import '../../features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import '../../features/leaderboard/domain/repositories/leaderboard_repository.dart';
import '../../features/profile/data/datasources/profile_remote_data_source.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import 'package:aura_app/core/data/repositories/seed_duty_repository.dart';
import 'package:aura_app/core/data/repositories/seed_knowledge_repository.dart';
import 'package:aura_app/core/data/repositories/seed_people_repository.dart';
import 'package:aura_app/core/data/repositories/seed_settings_repository.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_cubit.dart';
import 'package:aura_app/core/settings/locale_cubit.dart';
import 'package:aura_app/core/settings/theme_cubit.dart';
import 'package:aura_app/core/domain/repositories/duty_repository.dart';
import 'package:aura_app/core/domain/repositories/knowledge_repository.dart';
import 'package:aura_app/core/domain/repositories/people_repository.dart';
import 'package:aura_app/core/domain/repositories/settings_repository.dart';

/// Service locator. Bind domain interfaces to seed-backed implementations here;
/// swap to Firestore-backed impls without touching presentation.
/// See commands/02_architecture.md (Dependency injection).
final sl = GetIt.instance;

Future<void> setupDi() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

  // Auth (Firebase + Google).
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl()),
  );
  sl.registerFactory<AuthCubit>(() => AuthCubit(sl()));

  // Leaderboard (Firebase users).
  sl.registerLazySingleton<LeaderboardRemoteDataSource>(
    () => LeaderboardRemoteDataSourceImpl(FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<LeaderboardRepository>(
    () => LeaderboardRepositoryImpl(sl(), FirebaseAuth.instance),
  );

  // Award (Firebase: write transaction + increment recipient).
  sl.registerLazySingleton<AwardRemoteDataSource>(
    () => AwardRemoteDataSourceImpl(FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<AwardRepository>(
    () => AwardRepositoryImpl(sl(), sl()),
  );

  // Profile (Firebase: user doc + received-aura history).
  sl.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(FirebaseFirestore.instance),
  );
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(sl()),
  );

  // Repositories (seed-backed).
  sl.registerLazySingleton<PeopleRepository>(() => SeedPeopleRepository());
  sl.registerLazySingleton<DutyRepository>(() => SeedDutyRepository());
  sl.registerLazySingleton<KnowledgeRepository>(
    () => SeedKnowledgeRepository(),
  );
  sl.registerLazySingleton<SettingsRepository>(
    () => SeedSettingsRepository(),
  );

  // App-global cubits (single instance).
  sl.registerLazySingleton<ThemeCubit>(() => ThemeCubit(sl()));
  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit(sl()));
}
