class AiReceiptItem {
  const AiReceiptItem({
    required this.name,
    required this.amount,
    this.itemType,
  });

  final String name;
  final double amount;
  final String? itemType;
}

class AiReceiptAnalysis {
  const AiReceiptAnalysis({
    required this.reply,
    this.totalAmount,
    this.netAmount,
    this.categoryHint,
    this.transactionTypeHint,
    this.items = const <AiReceiptItem>[],
  });

  final String reply;
  final double? totalAmount;
  final double? netAmount;
  final String? categoryHint;
  final String? transactionTypeHint;
  final List<AiReceiptItem> items;
}
