class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.avatarBase64,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    required this.isActive,
  });

  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? avatarBase64;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final bool isActive;
}
