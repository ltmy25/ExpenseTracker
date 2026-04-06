import 'dart:typed_data';

import 'package:expensetracker/domain/entities/app_user.dart';
import 'package:expensetracker/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String displayName,
    Uint8List? avatarBytes,
    bool removeAvatar = false,
  }) {
    return _repository.updateProfile(
      displayName: displayName,
      avatarBytes: avatarBytes,
      removeAvatar: removeAvatar,
    );
  }
}
