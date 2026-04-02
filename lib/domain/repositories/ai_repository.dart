import 'package:expensetracker/domain/entities/ai_chat_response.dart';

abstract class AiRepository {
  Future<AiChatResponse> generateReply({
    required String message,
    required String financialContext,
  });
}
