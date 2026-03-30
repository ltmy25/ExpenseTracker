class Jar {
  final String id;
  final String name;
  final double currentBalance;
  final List<String>? categoryIds;
  final double? budgetLimit;
  final String? color;
  final String? icon;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Jar({
    required this.id,
    required this.name,
    required this.currentBalance,
    this.categoryIds,
    this.budgetLimit,
    this.color,
    this.icon,
    required this.createdAt,
    required this.updatedAt,
  });
}
