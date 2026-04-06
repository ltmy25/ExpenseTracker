import '../entities/category.dart';

abstract class CategoryRepository {
  Stream<List<Category>> getCategories(String userId);
  Future<void> addCategory(String userId, Category category);
  Future<void> updateCategory(String userId, Category category);
  Future<void> deleteCategory(String userId, String categoryId);
  Future<void> seedDefaultCategories(String userId); // Hàm tạo mẫu
}
