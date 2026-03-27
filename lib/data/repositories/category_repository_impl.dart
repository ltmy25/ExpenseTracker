import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/category_repository.dart';
import '../models/category_model.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final firestore.FirebaseFirestore _firestore = firestore.FirebaseFirestore.instance;

  @override
  Stream<List<Category>> getCategories(String userId) {
    return _firestore
        .collection('categories')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((firestore.QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
            .map((firestore.QueryDocumentSnapshot<Map<String, dynamic>> doc) => 
                CategoryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  @override
  Future<void> addCategory(String userId, Category category) async {
    final now = DateTime.now();
    final model = CategoryModel(
      id: '',
      userId: userId,
      name: category.name,
      icon: category.icon,
      color: category.color,
      type: category.type,
      isDefault: category.isDefault,
    );
    await _firestore.collection('categories').add(model.toMap(now));
  }

  @override
  Future<void> seedDefaultCategories(String userId) async {
    final now = DateTime.now();
    final batch = _firestore.batch();
    
    final List<Map<String, dynamic>> defaults = [
      {
        'id': 'cat_food_${userId}',
        'name': 'Ăn uống',
        'icon': 'restaurant',
        'type': 'expense',
        'color': '#FFF44336'
      },
      {
        'id': 'cat_salary_${userId}',
        'name': 'Tiền lương',
        'icon': 'payments',
        'type': 'income',
        'color': '#FF4CAF50'
      },
      {
        'id': 'cat_transport_${userId}',
        'name': 'Di chuyển',
        'icon': 'directions_car',
        'type': 'expense',
        'color': '#FF2196F3'
      },
      {
        'id': 'cat_study_${userId}',
        'name': 'Học tập',
        'icon': 'school',
        'type': 'expense',
        'color': '#FFFF9800'
      },
    ];

    for (var cat in defaults) {
      final docRef = _firestore.collection('categories').doc(cat['id']);
      batch.set(docRef, {
        'userId': userId,
        'name': cat['name'],
        'type': cat['type'],
        'icon': cat['icon'],
        'color': cat['color'],
        'isDefault': true,
        'createdAt': firestore.Timestamp.fromDate(now),
        'updatedAt': firestore.Timestamp.fromDate(now),
      });
    }

    await batch.commit();
  }

  @override
  Future<void> updateCategory(String userId, Category category) async {
    final now = DateTime.now();
    await _firestore.collection('categories').doc(category.id).update({
      'name': category.name,
      'icon': category.icon,
      'color': category.color,
      'updatedAt': firestore.Timestamp.fromDate(now),
    });
  }

  @override
  Future<void> deleteCategory(String userId, String categoryId) async {
    await _firestore.collection('categories').doc(categoryId).delete();
  }
}
