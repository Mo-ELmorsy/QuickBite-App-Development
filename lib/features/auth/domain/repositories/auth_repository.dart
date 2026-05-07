import '../entities/app_user_entity.dart';

abstract class AuthRepository {
  Stream<AppUserEntity?> authStateChanges();
  Future<AppUserEntity?> getCurrentUser();
  Future<AppUserEntity> signInWithGoogle();
  Future<AppUserEntity> signInDemoAsRole(String role);
  Future<void> signOut();
}
