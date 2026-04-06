class AiChatResponse {
  const AiChatResponse({
    required this.reply,
    this.savingAdvice,
    this.spendingAlerts = const <String>[],
  });

  final String reply;
  final String? savingAdvice;
  final List<String> spendingAlerts;
}
