import 'transaction.dart';

class Category {
  final String id;
  final String userId;
  final String name;
  final String icon;
  final String color; // Đổi từ int sang String để khớp Rules
  final TransactionType type; // Thêm type (income/expense) theo Rules
  final bool isDefault;

  Category({
    required this.id,
    required this.userId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    this.isDefault = false,
  });
}
