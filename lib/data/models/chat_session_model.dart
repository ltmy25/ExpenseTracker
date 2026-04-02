import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expensetracker/domain/entities/chat_session.dart';

class ChatSessionModel extends ChatSession {
  const ChatSessionModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.lastMessage,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ChatSessionModel.fromMap(Map<String, dynamic> map, String id) {
    return ChatSessionModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? 'Chat mới',
      lastMessage: map['lastMessage'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'lastMessage': lastMessage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
