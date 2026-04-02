import 'package:expensetracker/domain/entities/parsed_transaction_draft.dart';

enum ChatSender { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.userId,
    required this.sender,
    required this.text,
    required this.createdAt,
    this.savingAdvice,
    this.spendingAlerts = const <String>[],
    this.transactionDraft,
  });

  final String id;
  final String chatId;
  final String userId;
  final ChatSender sender;
  final String text;
  final DateTime createdAt;
  final String? savingAdvice;
  final List<String> spendingAlerts;
  final ParsedTransactionDraft? transactionDraft;
}
