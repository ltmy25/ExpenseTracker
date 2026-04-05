import 'package:expensetracker/domain/entities/parsed_transaction_draft.dart';
import 'package:expensetracker/domain/entities/transaction.dart';

class TransactionMessageParser {
  const TransactionMessageParser();

  static final RegExp _compactMillionRegex = RegExp(
    r'(\d+)\s*(tr|trieu|tri[eệ]u|m)\s*(\d{1,3})(?!\d)',
    caseSensitive: false,
  );

  static final RegExp _amountRegex = RegExp(
    r'((?:\d+[\d\.,]*)(?:\s*\d{3})?)\s*(k|ngan|nghin|ngh[iìíỉĩị]n|cu|c[uủ]|tr|trieu|tri[eệ]u|m|ty|t[yỷ])?',
    caseSensitive: false,
  );

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
    double? best;

    for (final match in _compactMillionRegex.allMatches(text)) {
      final major = double.tryParse(match.group(1) ?? '');
      final minorDigits = match.group(3) ?? '';
      final minor = double.tryParse('0.$minorDigits') ?? 0;
      if (major == null) {
        continue;
      }

      final value = (major + minor) * 1000000;
      if (best == null || value > best) {
        best = value;
      }
    }

    for (final match in _amountRegex.allMatches(text)) {
      final rawNumber = (match.group(1) ?? '').trim();
      final unit = (match.group(2) ?? '').toLowerCase().trim();
      final parsed = _parseRawNumber(rawNumber, hasUnit: unit.isNotEmpty);
      if (parsed == null || parsed <= 0) {
        continue;
      }

      final multiplier = _unitMultiplier(unit);
      final value = parsed * multiplier;

      if (best == null || value > best) {
        best = value;
      }
    }

    return best;
  }

  double? _parseRawNumber(String raw, {required bool hasUnit}) {
    if (raw.isEmpty) {
      return null;
    }

    var normalized = raw.replaceAll(' ', '');
    final hasDot = normalized.contains('.');
    final hasComma = normalized.contains(',');

    if (hasDot && hasComma) {
      normalized = normalized.replaceAll('.', '').replaceAll(',', '.');
    } else if (hasComma) {
      final firstComma = normalized.indexOf(',');
      final decimalDigits = normalized.length - firstComma - 1;
      if (hasUnit && normalized.indexOf(',') == normalized.lastIndexOf(',') && decimalDigits <= 2) {
        normalized = normalized.replaceAll(',', '.');
      } else {
        normalized = normalized.replaceAll(',', '');
      }
    } else {
      final firstDot = normalized.indexOf('.');
      final decimalDigits = normalized.length - firstDot - 1;
      if (hasUnit && normalized.indexOf('.') == normalized.lastIndexOf('.') && decimalDigits <= 2) {
        // Keep single decimal separator for forms like 3.4tr or 1.5m.
      } else {
        normalized = normalized.replaceAll('.', '');
      }
    }

    return double.tryParse(normalized);
  }

  double _unitMultiplier(String unit) {
    if (unit.isEmpty) {
      return 1;
    }

    if (RegExp(r'^(k|ngan|nghin|ngh[iìíỉĩị]n|cu|c[uủ])$').hasMatch(unit)) {
      return 1000;
    }
    if (RegExp(r'^(tr|trieu|tri[eệ]u|m)$').hasMatch(unit)) {
      return 1000000;
    }
    if (RegExp(r'^(ty|t[yỷ])$').hasMatch(unit)) {
      return 1000000000;
    }

    return 1;
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
