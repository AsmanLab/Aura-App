# 08 · Feature Setup Playbook (data · domain · presentation, BLoC)

How to add a new feature so it matches the rest of the app: three layers, dependencies pointing
**inward**, BLoC for state, `get_it` for wiring. See [`02_architecture.md`](02_architecture.md) for
the project-wide rules; this is the step-by-step recipe.

> Worked example below = a hypothetical **Streak** feature (a daily activity streak). Swap
> `streak`/`Streak` for your feature name.

---

## 0. The shape

```
lib/features/streak/
├── data/
│   ├── datasources/
│   │   └── streak_remote_data_source.dart   # raw IO (Firestore / seed / http)
│   ├── models/
│   │   └── streak_model.dart                # DTO: fromMap/toMap, extends entity
│   └── repositories/
│       └── streak_repository_impl.dart      # implements domain interface
├── domain/
│   ├── entities/
│   │   └── streak.dart                      # plain immutable (Equatable)
│   ├── repositories/
│   │   └── streak_repository.dart           # abstract contract
│   └── usecases/
│       └── get_streak.dart                  # one action per file (optional-thin)
└── presentation/
    ├── bloc/
    │   ├── streak_cubit.dart                # or streak_bloc.dart (+ event/state)
    │   └── streak_state.dart
    ├── pages/
    │   └── streak_page.dart
    └── widgets/
        └── streak_card.dart                 # feature-only widgets
```

**Dependency direction:** `presentation → domain ← data`. `domain` is pure Dart — no
`package:flutter`, no `cloud_firestore`, no `flutter_bloc`.

---

## 1. Domain first (pure Dart)

### Entity — `domain/entities/streak.dart`
```dart
import 'package:equatable/equatable.dart';

class Streak extends Equatable {
  final int current;
  final int best;
  final DateTime? lastActive;

  const Streak({required this.current, required this.best, this.lastActive});

  @override
  List<Object?> get props => [current, best, lastActive];
}
```

### Repository interface — `domain/repositories/streak_repository.dart`
```dart
import '../entities/streak.dart';

abstract class StreakRepository {
  Future<Streak> getStreak(String userId);
  Future<Streak> bumpStreak(String userId);
}
```

### Use case (optional) — `domain/usecases/get_streak.dart`
Use one when there's logic worth a name; for a pure pass-through, the bloc may call the repository
directly. Keep them thin.
```dart
import '../entities/streak.dart';
import '../repositories/streak_repository.dart';

class GetStreak {
  final StreakRepository _repo;
  const GetStreak(this._repo);

  Future<Streak> call(String userId) => _repo.getStreak(userId);
}
```

---

## 2. Data layer (implements domain)

### Model — `data/models/streak_model.dart`
Converts at the data boundary. Extends the entity so it flows up as the domain type.
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/streak.dart';

class StreakModel extends Streak {
  const StreakModel({
    required super.current,
    required super.best,
    super.lastActive,
  });

  factory StreakModel.fromMap(Map<String, dynamic> map) => StreakModel(
        current: map['current'] ?? 0,
        best: map['best'] ?? 0,
        lastActive: (map['lastActive'] as Timestamp?)?.toDate(),
      );

  Map<String, dynamic> toMap() => {
        'current': current,
        'best': best,
        'lastActive':
            lastActive == null ? null : Timestamp.fromDate(lastActive!),
      };
}
```

### Data source — `data/datasources/streak_remote_data_source.dart`
Raw IO only. No domain logic.
```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';

abstract class StreakRemoteDataSource {
  Future<StreakModel> fetch(String userId);
}

class StreakRemoteDataSourceImpl implements StreakRemoteDataSource {
  final FirebaseFirestore _db;
  StreakRemoteDataSourceImpl(this._db);

  @override
  Future<StreakModel> fetch(String userId) async {
    final doc = await _db.collection('streaks').doc(userId).get();
    return StreakModel.fromMap(doc.data() ?? const {});
  }
}
```
> For a seed/no-backend feature, write a `SeedStreakRepository` straight over in-memory data
> instead — same pattern as [`data/repositories/seed_people_repository.dart`](../lib/data/repositories/seed_people_repository.dart).

### Repository impl — `data/repositories/streak_repository_impl.dart`
```dart
import '../../domain/entities/streak.dart';
import '../../domain/repositories/streak_repository.dart';
import '../datasources/streak_remote_data_source.dart';

class StreakRepositoryImpl implements StreakRepository {
  final StreakRemoteDataSource _remote;
  StreakRepositoryImpl(this._remote);

  @override
  Future<Streak> getStreak(String userId) => _remote.fetch(userId);

  @override
  Future<Streak> bumpStreak(String userId) {
    // map models ↔ entities, orchestrate sources here
    throw UnimplementedError();
  }
}
```

---

## 3. Presentation (BLoC)

Use **`Cubit`** for simple state (loads, toggles, filters). Use **`Bloc`** (events → states) for
multi-step / event-driven flows. State classes are immutable and extend `Equatable`; emit new
instances, never mutate.

### State — `presentation/bloc/streak_state.dart`
```dart
import 'package:equatable/equatable.dart';
import '../../domain/entities/streak.dart';

class StreakState extends Equatable {
  final Streak? streak;
  final bool loading;

  const StreakState({this.streak, this.loading = true});

  StreakState copyWith({Streak? streak, bool? loading}) => StreakState(
        streak: streak ?? this.streak,
        loading: loading ?? this.loading,
      );

  @override
  List<Object?> get props => [streak, loading];
}
```

### Cubit — `presentation/bloc/streak_cubit.dart`
Depends on **domain** (use case / repository interface), never on `data` directly.
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_streak.dart';
import 'streak_state.dart';

class StreakCubit extends Cubit<StreakState> {
  final GetStreak _getStreak;

  StreakCubit(this._getStreak) : super(const StreakState());

  Future<void> load(String userId) async {
    emit(state.copyWith(loading: true));
    final streak = await _getStreak(userId);
    emit(state.copyWith(streak: streak, loading: false));
  }
}
```

### Page — `presentation/pages/streak_page.dart`
Provide the bloc at the route (or via `MultiBlocProvider`); render with `BlocBuilder`.
```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/streak_cubit.dart';
import '../bloc/streak_state.dart';

class StreakPage extends StatelessWidget {
  const StreakPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AppColors>()!;
    return Scaffold(
      backgroundColor: c.bg,
      body: BlocBuilder<StreakCubit, StreakState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Center(child: Text('Streak: ${state.streak?.current ?? 0}'));
        },
      ),
    );
  }
}
```

---

## 4. Dependency injection — `core/di/injection.dart`

Register **inner-to-outer**: data source → repository → use case → bloc. Repositories and use cases
are `lazySingleton`; blocs are `factory` (fresh per screen).

```dart
// data source
sl.registerLazySingleton<StreakRemoteDataSource>(
  () => StreakRemoteDataSourceImpl(sl()),     // sl() resolves FirebaseFirestore
);
// repository (interface → impl)
sl.registerLazySingleton<StreakRepository>(
  () => StreakRepositoryImpl(sl()),
);
// use case
sl.registerLazySingleton(() => GetStreak(sl()));
// bloc — factory: new instance per route
sl.registerFactory(() => StreakCubit(sl()));
```
> External singletons (e.g. `FirebaseFirestore.instance`, `SharedPreferences`) are registered once
> at the top of `setupDi()`. See the existing [`injection.dart`](../lib/core/di/injection.dart).

---

## 5. Wire the route — `core/router/app_router.dart`

Provide the bloc in the route builder so it's scoped to the screen:
```dart
GoRoute(
  path: '/aura/streak',
  builder: (context, state) => BlocProvider(
    create: (_) => sl<StreakCubit>()..load('aibek'),
    child: const StreakPage(),
  ),
),
```
App-global blocs (theme, locale) are provided once above `MaterialApp` with `BlocProvider.value`
from `sl`, not per route.

---

## 6. Checklist

- [ ] `domain/` has **no** Flutter / Firebase / BLoC imports.
- [ ] Entities + states extend `Equatable`; states are immutable (`copyWith`, no mutation).
- [ ] Bloc depends on domain (use case / repo interface) — never on a `data` class.
- [ ] Model `fromMap`/`toMap` is the **only** place that touches `Timestamp` / raw maps.
- [ ] Repository interface in `domain`, impl in `data`, bound in `get_it`.
- [ ] Bloc = `registerFactory`; repo / use case = `registerLazySingleton`.
- [ ] Shared widgets (used by ≥2 features) live in `shared/widgets/`, not the feature folder.
- [ ] `flutter analyze` clean.

---

## 7. Naming conventions

| Thing | Pattern | Example |
|-------|---------|---------|
| Entity | noun | `Streak` |
| Model | `<Entity>Model` | `StreakModel` |
| Repo interface | `<Feature>Repository` | `StreakRepository` |
| Repo impl | `<Feature>RepositoryImpl` / `Seed<Feature>Repository` | `StreakRepositoryImpl` |
| Data source | `<Feature>RemoteDataSource` / `...LocalDataSource` | `StreakRemoteDataSource` |
| Use case | verb phrase | `GetStreak`, `BumpStreak` |
| Cubit / Bloc | `<Feature>Cubit` / `<Feature>Bloc` | `StreakCubit` |
| State / Event | `<Feature>State` / `<Feature>Event` | `StreakState` |
| Page | `<Feature>Page` | `StreakPage` |
