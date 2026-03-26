import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetracker/domain/entities/app_user.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.uid,
    required super.email,
    required super.displayName,
    super.photoUrl,
    required super.createdAt,
    required super.updatedAt,
    super.lastLoginAt,
    required super.isActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    final createdAt = (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
    final updatedAt = (map['updatedAt'] as Timestamp?)?.toDate() ?? createdAt;
    final lastLoginAt = (map['lastLoginAt'] as Timestamp?)?.toDate();

    return UserModel(
      uid: uid,
      email: (map['email'] as String?) ?? '',
      displayName: (map['displayName'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastLoginAt: lastLoginAt,
      isActive: (map['isActive'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
    };
  }

  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    bool? isActive,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
    );
  }

  factory UserModel.fromAuthUser({
    required String uid,
    required String email,
    required String displayName,
    String? photoUrl,
  }) {
    final now = DateTime.now();
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoUrl: photoUrl,
      createdAt: now,
      updatedAt: now,
      lastLoginAt: now,
      isActive: true,
    );
  }
}
