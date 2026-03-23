import 'package:injectable/injectable.dart';
import 'package:kakikaki/features/my/data/source/user_remote_data_source.dart';
import 'package:kakikaki/features/my/domain/repository/user_repository.dart';

@Injectable(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._remoteDataSource);

  final UserRemoteDataSource _remoteDataSource;

  @override
  Future<void> updateNickname({
    required String userId,
    required String newNickname,
  }) =>
      _remoteDataSource.updateNickname(
        userId: userId,
        newNickname: newNickname,
      );

  @override
  Future<void> deleteAccount({String? reason}) =>
      _remoteDataSource.deleteAccount(reason: reason);

  @override
  Future<bool> checkPremiumStatus({required String userId}) =>
      _remoteDataSource.checkPremiumStatus(userId: userId);
}
