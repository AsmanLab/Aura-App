import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/repositories/seed_duty_repository.dart';
import '../../data/repositories/seed_knowledge_repository.dart';
import '../../data/repositories/seed_people_repository.dart';
import '../../data/repositories/seed_settings_repository.dart';
import '../../features/settings/presentation/bloc/locale_cubit.dart';
import '../../features/settings/presentation/bloc/theme_cubit.dart';
import '../../shared/domain/repositories/duty_repository.dart';
import '../../shared/domain/repositories/knowledge_repository.dart';
import '../../shared/domain/repositories/people_repository.dart';
import '../../shared/domain/repositories/settings_repository.dart';

/// Service locator. Bind domain interfaces to seed-backed implementations here;
/// swap to Firestore-backed impls without touching presentation.
/// See commands/02_architecture.md (Dependency injection).
final sl = GetIt.instance;

Future<void> setupDi() async {
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);

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
