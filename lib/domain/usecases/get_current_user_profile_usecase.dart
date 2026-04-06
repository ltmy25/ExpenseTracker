import 'package:expensetracker/domain/entities/app_user.dart';
import 'package:expensetracker/domain/repositories/auth_repository.dart';

class GetCurrentUserProfileUseCase {
  const GetCurrentUserProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<AppUser?> call() {
    return _repository.getCurrentUserProfile();
  }
}
