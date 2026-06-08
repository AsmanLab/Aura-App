import 'package:aura_app/core/models/user_model.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  AuthRepositoryImpl(this._remote);

  @override
  Stream<bool> authStateChanges() =>
      _remote.authStateChanges().map((u) => u != null);

  @override
  Stream<UserModel?> currentUserProfile() => _remote.currentUserProfile();

  @override
  AppUser? get currentUser {
    final u = _remote.currentUser;
    return u == null ? null : AppUserModel.fromFirebaseUser(u);
  }

  @override
  Future<AppUser?> signInWithGoogle() => _remote.signInWithGoogle();

  @override
  Future<void> signOut() => _remote.signOut();
}
