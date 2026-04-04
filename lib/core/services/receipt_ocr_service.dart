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
    r'^(.*?)[\s\-xX]*([0-9]{1,3}(?:[\.,\s][0-9]{3})+|[0-9]{2,})\s*(?:đ|d|vnd|vnđ)?$',
    caseSensitive: false,
  );

  static const List<String> _ignoredKeywords = [
    'tong',
    'total',
    'thanh tien',
    'cong',
    'giam gia',
    'discount',
    'tien mat',
    'chuyen khoan',
    'thue',
    'vat',
    'cash',
    'change',
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

    for (final line in lines) {
      final parsed = _parseLine(line);
      if (parsed != null) {
        items.add(parsed);
      }
    }

    return _deduplicate(items);
  }

  ReceiptOcrItem? _parseLine(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) {
      return null;
    }

    final normalized = text.toLowerCase();
    for (final keyword in _ignoredKeywords) {
      if (normalized.contains(keyword)) {
        return null;
      }
    }

    final match = _linePattern.firstMatch(text);
    if (match == null) {
      return null;
    }

    final rawName = (match.group(1) ?? '').trim();
    final rawAmount = (match.group(2) ?? '').trim();

    if (rawName.isEmpty || rawName.length < 2) {
      return null;
    }

    final digitsOnly = rawAmount.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    final amount = double.tryParse(digitsOnly);
    if (amount == null || amount < 100) {
      return null;
    }

    return ReceiptOcrItem(name: rawName, amount: amount);
  }

  List<ReceiptOcrItem> _deduplicate(List<ReceiptOcrItem> source) {
    final unique = <String, ReceiptOcrItem>{};

    for (final item in source) {
      final key = '${item.name.toLowerCase()}_${item.amount.toInt()}';
      unique[key] = item;
    }

    final items = unique.values.toList();
    items.sort((a, b) => b.amount.compareTo(a.amount));

    return items.take(min(items.length, 20)).toList();
  }
}
