import 'dart:math';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'web_tesseract_ocr_stub.dart'
  if (dart.library.html) 'web_tesseract_ocr_web.dart';

class ReceiptOcrItem {
  ReceiptOcrItem({
    required this.name,
    required this.amount,
  });

  final String name;
  final double amount;
}

class ReceiptOcrService {
  static final RegExp _linePattern = RegExp(
    r'^(.*?)([0-9OoIlLS]{1,3}(?:[\.,\s][0-9OoIlLS]{3})+|[0-9OoIlLS]{3,})\s*(?:đ|d|vnd|vnđ)?\s*$',
    caseSensitive: false,
  );

  static final RegExp _amountOnlyPattern = RegExp(
    r'^\s*([0-9OoIlLS]{1,3}(?:[\.,\s][0-9OoIlLS]{3})+|[0-9OoIlLS]{3,})\s*(?:đ|d|vnd|vnđ)?\s*$',
    caseSensitive: false,
  );

  static final RegExp _amountTokenPattern = RegExp(
    r'[0-9OoIlLS]{1,3}(?:[\.,\s][0-9OoIlLS]{3})+|[0-9OoIlLS]{3,}',
    caseSensitive: false,
  );

  static final RegExp _dateTimePattern = RegExp(
    r'(\b\d{1,2}[\/\-]\d{1,2}(?:[\/\-]\d{2,4})?\b|\b\d{1,2}:\d{2}\b)',
  );

  static final RegExp _nonWordCollapse = RegExp(r'[^\p{L}\p{N}\s]', unicode: true);
  static final RegExp _multiSpace = RegExp(r'\s+');

  static const List<String> _ignoredKeywords = [
    'tong',
    'tong cong',
    'total',
    'subtotal',
    'sub total',
    'thanh tien',
    'tien hang',
    'tam tinh',
    'cong',
    'giam gia',
    'discount',
    'promotion',
    'khuyen mai',
    'voucher',
    'tien mat',
    'khach tra',
    'so tien nhan',
    'tra lai',
    'chuyen khoan',
    'thue',
    'vat',
    'phi dich vu',
    'service charge',
    'invoice',
    'hoa don',
    'mst',
    'dia chi',
    'dien thoai',
    'tel',
    'cash',
    'change',
    'ban',
    'so hd',
    'ma gd',
  ];

  Future<List<ReceiptOcrItem>> extractItemsFromImagePath(String imagePath) async {
    if (kIsWeb) {
      final text = await extractTextWithWebTesseract(imagePath);
      return _extractItemsFromRawText(text);
    }

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final result = await recognizer.processImage(inputImage);

      final lines = <String>[];
      for (final block in result.blocks) {
        for (final line in block.lines) {
          lines.add(line.text);
        }
      }

      return _extractItemsFromRawText(lines.join('\n'));
    } finally {
      await recognizer.close();
    }
  }

  List<ReceiptOcrItem> _extractItemsFromRawText(String rawText) {
    final items = <ReceiptOcrItem>[];
    final lines = rawText.split(RegExp(r'\r?\n'));
    String? pendingName;

    for (final line in lines) {
      final parsed = _parseLine(line, fallbackName: pendingName);
      if (parsed != null) {
        items.add(parsed);
        pendingName = null;
        continue;
      }

      final amountOnly = _parseAmountOnly(line);
      if (amountOnly != null && pendingName != null) {
        items.add(ReceiptOcrItem(name: pendingName, amount: amountOnly));
        pendingName = null;
        continue;
      }

      if (_looksLikeItemName(line)) {
        pendingName = _cleanName(line);
      }
    }

    return _deduplicate(items);
  }

  ReceiptOcrItem? _parseLine(String rawText, {String? fallbackName}) {
    final text = _sanitizeLine(rawText);
    if (text.isEmpty) {
      return null;
    }

    if (_dateTimePattern.hasMatch(text)) {
      return null;
    }

    final normalized = _normalizeForCompare(text);
    for (final keyword in _ignoredKeywords) {
      if (normalized.contains(keyword)) {
        return null;
      }
    }

    final simpleMatch = _linePattern.firstMatch(text);
    if (simpleMatch != null) {
      var rawName = _cleanName((simpleMatch.group(1) ?? '').trim());
      final rawAmount = (simpleMatch.group(2) ?? '').trim();

      if ((rawName.isEmpty || rawName.length < 2) && fallbackName != null) {
        rawName = fallbackName;
      }

      if (rawName.isNotEmpty && !_looksNumeric(rawName)) {
        final amount = _parseAmount(rawAmount);
        if (amount != null) {
          return ReceiptOcrItem(name: rawName, amount: amount);
        }
      }
    }

    final amountMatches = _amountTokenPattern.allMatches(text).toList();
    if (amountMatches.isEmpty) {
      return null;
    }

    final amounts = <double>[];
    for (final match in amountMatches) {
      final parsedAmount = _parseAmount(match.group(0) ?? '');
      if (parsedAmount != null) {
        amounts.add(parsedAmount);
      }
    }

    if (amounts.isEmpty) {
      return null;
    }

    var name = _cleanName(text.substring(0, amountMatches.first.start));
    if ((name.isEmpty || name.length < 2) && fallbackName != null) {
      name = fallbackName;
    }

    if (name.isEmpty || _looksNumeric(name)) {
      return null;
    }

    final amount = amounts.last;
    return ReceiptOcrItem(name: name, amount: amount);
  }

  double? _parseAmountOnly(String rawText) {
    final text = _sanitizeLine(rawText);
    if (text.isEmpty) {
      return null;
    }

    final match = _amountOnlyPattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    return _parseAmount(match.group(1) ?? '');
  }

  double? _parseAmount(String raw) {
    final normalized = _normalizeAmountToken(raw);
    final digitsOnly = normalized.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    final amount = double.tryParse(digitsOnly);
    if (amount == null) {
      return null;
    }

    if (amount < 500 || amount > 50000000) {
      return null;
    }

    return amount;
  }

  String _normalizeAmountToken(String raw) {
    return raw
        .toUpperCase()
        .replaceAll('O', '0')
        .replaceAll('Q', '0')
        .replaceAll('I', '1')
        .replaceAll('L', '1')
        .replaceAll('S', '5');
  }

  bool _looksLikeItemName(String rawText) {
    final text = _cleanName(rawText);
    if (text.length < 2) {
      return false;
    }

    if (_looksNumeric(text)) {
      return false;
    }

    final digitCount = RegExp(r'\d').allMatches(text).length;
    if (digitCount > text.length * 0.4) {
      return false;
    }

    final normalized = _normalizeForCompare(text);
    for (final keyword in _ignoredKeywords) {
      if (normalized.contains(keyword)) {
        return false;
      }
    }

    return true;
  }

  bool _looksNumeric(String text) {
    final noSpace = text.replaceAll(' ', '');
    return RegExp(r'^[0-9]+$').hasMatch(noSpace);
  }

  String _sanitizeLine(String value) {
    return value
        .replaceAll('\t', ' ')
        .replaceAll('—', '-')
        .replaceAll('–', '-')
        .trim();
  }

  String _cleanName(String value) {
    var text = value;
    text = text.replaceAll(_nonWordCollapse, ' ');
    text = text.replaceAll(_multiSpace, ' ').trim();
    text = text.replaceAll(RegExp(r'^\d+\s*[xX]\s*'), '');
    text = text.replaceAll(RegExp(r'\b(sl|so luong)\s*\d+\b', caseSensitive: false), '');
    text = text.replaceAll(_multiSpace, ' ').trim();
    return text;
  }

  String _normalizeForCompare(String input) {
    var text = input.toLowerCase();
    const withAccent = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const withoutAccent = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiioooooooooooooooooouuuuuuuuuuuyyyyyd';

    for (var i = 0; i < withAccent.length; i++) {
      text = text.replaceAll(withAccent[i], withoutAccent[i]);
    }

    text = text.replaceAll(_nonWordCollapse, ' ');
    text = text.replaceAll(_multiSpace, ' ').trim();
    return text;
  }

  List<ReceiptOcrItem> _deduplicate(List<ReceiptOcrItem> source) {
    final unique = <String, ReceiptOcrItem>{};

    for (final item in source) {
      final cleanedName = _normalizeForCompare(item.name);
      final key = '${cleanedName}_${item.amount.toInt()}';
      unique[key] = item;
    }

    final items = unique.values.toList();
    items.sort((a, b) => b.amount.compareTo(a.amount));

    return items.take(min(items.length, 20)).toList();
  }
}
