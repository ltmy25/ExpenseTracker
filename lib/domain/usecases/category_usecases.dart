import '../entities/category.dart';
import '../repositories/category_repository.dart';

class GetCategoriesUseCase {
  final CategoryRepository repository;
  GetCategoriesUseCase(this.repository);
  Stream<List<Category>> call(String userId) => repository.getCategories(userId);
}

class AddCategoryUseCase {
  final CategoryRepository repository;
  AddCategoryUseCase(this.repository);
  Future<void> call(String userId, Category category) => repository.addCategory(userId, category);
}

class UpdateCategoryUseCase {
  final CategoryRepository repository;
  UpdateCategoryUseCase(this.repository);
  Future<void> call(String userId, Category category) => repository.updateCategory(userId, category);
}

class DeleteCategoryUseCase {
  final CategoryRepository repository;
  DeleteCategoryUseCase(this.repository);
  Future<void> call(String userId, String categoryId) => repository.deleteCategory(userId, categoryId);
}
