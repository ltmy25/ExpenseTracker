import 'package:expensetracker/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AppUser> signIn({
    required String email,
    required String password,
  });

  Future<AppUser> signInWithGoogle();

  Future<void> signOut();

  Future<void> sendPasswordResetEmail({required String email});

  Future<AppUser> updateProfile({
    required String displayName,
    String? photoUrl,
  });

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  Future<AppUser?> getCurrentUserProfile();
}
