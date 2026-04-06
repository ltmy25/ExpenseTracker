class ChatSession {
  const ChatSession({
    required this.id,
    required this.userId,
    required this.title,
    required this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String title;
  final String lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;
}
