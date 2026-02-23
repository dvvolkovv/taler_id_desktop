import '../entities/user_entity.dart';

abstract class IProfileRepository {
  Future<UserEntity> getProfile();
}
