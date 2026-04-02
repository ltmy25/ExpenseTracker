import 'package:expensetracker/domain/entities/parsed_transaction_draft.dart';
import 'package:expensetracker/domain/entities/transaction.dart';

class TransactionMessageParser {
  const TransactionMessageParser();

  ParsedTransactionDraft? parse(String message) {
    final text = message.trim();
    if (text.isEmpty) return null;

    final normalized = text.toLowerCase();
    final amount = _extractAmount(normalized);
    if (amount == null || amount <= 0) return null;

    final type = _detectType(normalized);
    final hint = _detectCategoryHint(normalized, type);

    return ParsedTransactionDraft(
      title: _buildTitle(normalized, type),
      amount: amount,
      type: type,
      occurredAt: DateTime.now(),
      categoryHint: hint,
      note: text,
      confidence: hint == null ? 0.72 : 0.88,
    );
  }

  double? _extractAmount(String text) {
    final regex = RegExp(r'(\d+[\d\.,]*)\s*(k|ngan|ngh[iì]n|tr|tri[eệ]u|m|ty|t[yỉ])?');
    final match = regex.firstMatch(text);
    if (match == null) return null;

    final raw = (match.group(1) ?? '').replaceAll('.', '').replaceAll(',', '.');
    final base = double.tryParse(raw);
    if (base == null) return null;

    final unit = match.group(2) ?? '';
    if (RegExp(r'^(k|ngan|ngh[iì]n)$').hasMatch(unit)) return base * 1000;
    if (RegExp(r'^(tr|tri[eệ]u|m)$').hasMatch(unit)) return base * 1000000;
    if (RegExp(r'^(ty|t[yỉ])$').hasMatch(unit)) return base * 1000000000;
    return base;
  }

  TransactionType _detectType(String text) {
    const incomeKeywords = <String>[
      'thu',
      'nhan',
      'lương',
      'luong',
      'thưởng',
      'thuong',
      'hoàn tiền',
      'hoan tien',
      'được cho',
      'duoc cho',
    ];
    for (final keyword in incomeKeywords) {
      if (text.contains(keyword)) {
        return TransactionType.income;
      }
    }
    return TransactionType.expense;
  }

  String? _detectCategoryHint(String text, TransactionType type) {
    if (type == TransactionType.income) {
      if (text.contains('lương') || text.contains('luong')) return 'Tiền lương';
      if (text.contains('thưởng') || text.contains('thuong')) return 'Thưởng';
      return 'Thu nhập';
    }

    if (text.contains('ăn') || text.contains('uong') || text.contains('uống')) {
      return 'Ăn uống';
    }
    if (text.contains('xăng') || text.contains('xe') || text.contains('bus') || text.contains('taxi')) {
      return 'Di chuyển';
    }
    if (text.contains('học') || text.contains('sách') || text.contains('khoá học')) {
      return 'Học tập';
    }
    if (text.contains('mua')) return 'Mua sắm';
    return null;
  }

  String _buildTitle(String text, TransactionType type) {
    if (type == TransactionType.income) {
      return text.contains('lương') || text.contains('luong')
          ? 'Nhận lương'
          : 'Thu nhập từ chat';
    }

    if (text.contains('ăn') || text.contains('uong') || text.contains('uống')) {
      return 'Chi tiêu ăn uống';
    }
    if (text.contains('xăng') || text.contains('xe') || text.contains('bus') || text.contains('taxi')) {
      return 'Chi tiêu di chuyển';
    }
    return 'Chi tiêu từ chat';
  }
}
