import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';

import 'package:expensetracker/data/datasources/remote/auth_remote_datasource.dart';
import 'package:expensetracker/domain/entities/app_user.dart';
import 'package:expensetracker/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> authStateChanges() {
    return _remoteDataSource.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) {
        return null;
      }
      return _remoteDataSource.getCurrentUserProfile();
    });
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _remoteDataSource.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    return _remoteDataSource.signIn(email: email, password: password);
  }

  @override
  Future<AppUser> signInWithGoogle() {
    return _remoteDataSource.signInWithGoogle();
  }

  @override
  Future<void> signOut() {
    return _remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) {
    return _remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<AppUser> updateProfile({
    required String displayName,
    Uint8List? avatarBytes,
    bool removeAvatar = false,
  }) {
    return _remoteDataSource.updateProfile(
      displayName: displayName,
      avatarBytes: avatarBytes,
      removeAvatar: removeAvatar,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<AppUser?> getCurrentUserProfile() {
    return _remoteDataSource.getCurrentUserProfile();
  }

  String mapFirebaseAuthError(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }

    switch (error.code) {
      case 'email-already-in-use':
        return 'Email đã tồn tại.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'weak-password':
        return 'Mật khẩu quá yếu.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Thông tin đăng nhập không đúng.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      case 'sign-in-cancelled':
        return 'Đăng nhập Google đã bị hủy.';
      default:
        return error.message ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.';
    }
  }
}
