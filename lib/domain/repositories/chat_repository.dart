import 'package:expensetracker/domain/entities/chat_message.dart';
import 'package:expensetracker/domain/entities/chat_session.dart';

abstract class ChatRepository {
  Future<String> ensureUserChat(String userId);

  Future<String> createChatSession({
    required String userId,
    String? title,
  });

  Stream<List<ChatSession>> watchChatSessions(String userId);

  Stream<List<ChatMessage>> watchMessages(String chatId);

  Future<void> addMessage({
    required String chatId,
    required ChatMessage message,
  });

  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
  });

  Future<void> clearChatMessages(String chatId);

  Future<void> deleteChatSession(String chatId);
}
