class AiReceiptItem {
  const AiReceiptItem({
    required this.name,
    required this.amount,
  });

  final String name;
  final double amount;
}

class AiReceiptAnalysis {
  const AiReceiptAnalysis({
    required this.reply,
    this.items = const <AiReceiptItem>[],
  });

  final String reply;
  final List<AiReceiptItem> items;
}
