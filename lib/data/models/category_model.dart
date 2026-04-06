import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../../domain/entities/category.dart';
import '../../domain/entities/transaction.dart';

class CategoryModel extends Category {
  CategoryModel({
    required super.id,
    required super.userId,
    required super.name,
    required super.icon,
    required super.color,
    required super.type,
    super.isDefault,
  });

  Map<String, dynamic> toMap(DateTime now) => {
    'userId': userId,
    'name': name,
    'type': type.name, // 'income' or 'expense'
    'icon': icon,
    'color': color,
    'isDefault': isDefault,
    'createdAt': firestore.Timestamp.fromDate(now),
    'updatedAt': firestore.Timestamp.fromDate(now),
  };

  factory CategoryModel.fromMap(Map<String, dynamic> map, String id) {
    return CategoryModel(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      icon: map['icon'] ?? 'help_outline',
      color: map['color'] ?? '#FF9E9E9E',
      type: map['type'] == 'income' ? TransactionType.income : TransactionType.expense,
      isDefault: map['isDefault'] ?? false,
    );
  }
}
