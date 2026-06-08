import 'package:aura_app/core/models/aura_transaction.dart';
import 'package:aura_app/core/models/user_model.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_data_source.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remote;
  ProfileRepositoryImpl(this._remote);

  @override
  Future<UserModel?> getUser(String id) => _remote.getUser(id);

  @override
  Future<List<AuraTransaction>> getHistory(String userId) =>
      _remote.getHistory(userId);
}
