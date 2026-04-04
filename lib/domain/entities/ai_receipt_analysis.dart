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
    this.totalAmount,
    this.categoryHint,
    this.items = const <AiReceiptItem>[],
  });

  final String reply;
  final double? totalAmount;
  final String? categoryHint;
  final List<AiReceiptItem> items;
}
