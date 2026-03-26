import 'package:expensetracker/domain/entities/app_user.dart';
import 'package:expensetracker/domain/repositories/auth_repository.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String displayName,
    String? photoUrl,
  }) {
    return _repository.updateProfile(
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
