import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetracker/domain/entities/jar.dart';

class JarModel extends Jar {
  final String? userId;
  final List<String>? categoryIds;

  const JarModel({
    required super.id,
    this.userId,
    required super.name,
    required super.currentBalance,
    this.categoryIds,
    super.budgetLimit,
    super.color,
    super.icon,
    required super.createdAt,
    required super.updatedAt,
  });

  factory JarModel.fromMap(Map<String, dynamic> map, String id) {
    return JarModel(
      id: id,
      userId: map['userId'],
      name: map['name'] ?? '',
      currentBalance: (map['currentBalance'] ?? map['balance'] ?? 0.0).toDouble(),
      categoryIds: (map['categoryIds'] as List<dynamic>?)?.map((e) => e as String).toList(),
      budgetLimit: (map['budgetLimit'] ?? map['targetAmount'] as num?)?.toDouble(),
      color: map['color'],
      icon: map['icon'],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (userId != null) 'userId': userId,
      if (categoryIds != null) 'categoryIds': categoryIds,
      'name': name,
      'currentBalance': currentBalance,
      'budgetLimit': budgetLimit,
      'color': color,
      'icon': icon,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  JarModel copyWith({
    String? name,
    double? currentBalance,
    double? budgetLimit,
    String? color,
    String? icon,
    DateTime? updatedAt,
    String? userId,
    List<String>? categoryIds,
  }) {
    return JarModel(
      id: id,
      userId: userId ?? this.userId,
      categoryIds: categoryIds ?? this.categoryIds,
      name: name ?? this.name,
      currentBalance: currentBalance ?? this.currentBalance,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
