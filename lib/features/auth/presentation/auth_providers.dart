import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aura_app/core/di/injection.dart';
import 'package:aura_app/core/models/user_model.dart';
import '../domain/repositories/auth_repository.dart';

/// Riverpod bridge over the layered auth feature. Lets the legacy Firebase
/// screens + the GoRouter redirect keep consuming auth without a BLoC rewrite —
/// all delegate to the single [AuthRepository] held in get_it.
final authRepositoryProvider =
    Provider<AuthRepository>((_) => sl<AuthRepository>());

final authStateProvider = StreamProvider<bool>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final currentUserProvider = StreamProvider<UserModel?>(
  (ref) => ref.watch(authRepositoryProvider).currentUserProfile(),
);
