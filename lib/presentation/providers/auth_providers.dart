import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:expensetracker/data/datasources/remote/auth_remote_datasource.dart';
import 'package:expensetracker/data/repositories/auth_repository_impl.dart';
import 'package:expensetracker/domain/entities/app_user.dart';
import 'package:expensetracker/domain/repositories/auth_repository.dart';
import 'package:expensetracker/domain/usecases/change_password_usecase.dart';
import 'package:expensetracker/domain/usecases/get_current_user_profile_usecase.dart';
import 'package:expensetracker/domain/usecases/send_password_reset_email_usecase.dart';
import 'package:expensetracker/domain/usecases/sign_in_usecase.dart';
import 'package:expensetracker/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:expensetracker/domain/usecases/sign_out_usecase.dart';
import 'package:expensetracker/domain/usecases/sign_up_usecase.dart';
import 'package:expensetracker/domain/usecases/update_profile_usecase.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSource(
    firebaseAuth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final signInUseCaseProvider = Provider<SignInUseCase>((ref) {
  return SignInUseCase(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((ref) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final signUpUseCaseProvider = Provider<SignUpUseCase>((ref) {
  return SignUpUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(authRepositoryProvider));
});

final changePasswordUseCaseProvider = Provider<ChangePasswordUseCase>((ref) {
  return ChangePasswordUseCase(ref.watch(authRepositoryProvider));
});

final sendPasswordResetEmailUseCaseProvider = Provider<SendPasswordResetEmailUseCase>((ref) {
  return SendPasswordResetEmailUseCase(ref.watch(authRepositoryProvider));
});

final getCurrentUserProfileUseCaseProvider = Provider<GetCurrentUserProfileUseCase>((ref) {
  return GetCurrentUserProfileUseCase(ref.watch(authRepositoryProvider));
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._read) : super(const AsyncValue.data(null));

  final Ref _read;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _read.read(signInUseCaseProvider).call(email: email, password: password);
    });
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _read.read(signUpUseCaseProvider).call(
            email: email,
            password: password,
            displayName: displayName,
          );
    });
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _read.read(signInWithGoogleUseCaseProvider).call();
    });
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _read.read(signOutUseCaseProvider).call();
    });
  }

  Future<void> updateProfile({
    required String displayName,
    Uint8List? avatarBytes,
    bool removeAvatar = false,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _read.read(updateProfileUseCaseProvider).call(
            displayName: displayName,
            avatarBytes: avatarBytes,
            removeAvatar: removeAvatar,
          );
    });
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _read.read(changePasswordUseCaseProvider).call(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );
    });
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _read.read(sendPasswordResetEmailUseCaseProvider).call(email: email);
    });
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

final currentUserProfileProvider = FutureProvider<AppUser?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final authUser = authState.value;

  if (authUser == null) {
    return null;
  }

  final profile = await ref.watch(getCurrentUserProfileUseCaseProvider).call();
  if (profile == null) {
    return null;
  }

  // Ensure we never surface a stale cached profile from another account.
  if (profile.uid != authUser.uid) {
    return null;
  }

  return profile;
});
