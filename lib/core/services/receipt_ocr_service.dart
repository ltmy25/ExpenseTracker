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

class ReceiptOcrExtractionResult {
  ReceiptOcrExtractionResult({
    required this.items,
    required this.rawText,
    required this.sanitizedLines,
  });

  final List<ReceiptOcrItem> items;
  final String rawText;
  final List<String> sanitizedLines;
}

class ReceiptOcrService {
  static final RegExp _amountTokenPattern = RegExp(
    r'[0-9OoIlSsZz]{1,3}(?:[\.,][0-9OoIlSsZz]{3})+|[0-9OoIlSsZz]{4,}',
    caseSensitive: false,
  );

  static final RegExp _dateOrTimePattern = RegExp(
    r'(\b\d{1,2}:\d{2}\b)|(\b\d{1,2}[\/\-]\d{1,2}(?:[\/\-]\d{2,4})?\b)|(\b(19|20)\d{2}\b)',
    caseSensitive: false,
  );

  static const List<String> _headerKeywords = [
    'ten mon',
    'ten hang',
    'don gia',
    'd gia',
    'dgia',
    'thanh tien',
    'so luong',
    'sl',
    'tt',
  ];

  static const List<String> _footerKeywords = [
    'tong tien',
    'tong cong',
    'tien hang',
    'thanh tien',
    'thanh toan',
    'tien khach tra',
    'tien thua',
    'giam',
    'xin cam on',
    'tien mat',
    'cash',
    'change',
    'vat',
  ];

  static const List<String> _metadataKeywords = [
    'hoa don',
    'thanh toan',
    'so hd',
    'ma hd',
    'ban:',
    'ban so',
    'gio vao',
    'gio ra',
    'ngay',
    'nhan vien',
    'khach hang',
    'thu ngan',
    'khach le',
    'dia chi',
    'powered by',
    'ipos',
    'mst',
    'dt',
    'tel',
    'pos365',
    'the noodle house',
  ];

  Future<List<ReceiptOcrItem>> extractItemsFromImagePath(String imagePath) async {
    final result = await extractDetailedFromImagePath(imagePath);
    return result.items;
  }

  Future<ReceiptOcrExtractionResult> extractDetailedFromImagePath(String imagePath) async {
    final rawText = await _extractRawTextFromImagePath(imagePath);
    final sanitizedLines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_sanitizeLine)
        .where((line) => line.isNotEmpty)
        .toList();
    final items = _extractItemsFromRawText(rawText);

    return ReceiptOcrExtractionResult(
      items: items,
      rawText: rawText,
      sanitizedLines: sanitizedLines,
    );
  }

  Future<String> _extractRawTextFromImagePath(String imagePath) async {
    if (kIsWeb) {
      return extractTextWithWebTesseract(imagePath);
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

      return lines.join('\n');
    } finally {
      await recognizer.close();
    }
  }

  List<ReceiptOcrItem> _extractItemsFromRawText(String rawText) {
    final lines = rawText
        .split(RegExp(r'\r?\n'))
        .map(_sanitizeLine)
        .where((line) => line.isNotEmpty)
        .toList();

    final tableRange = _findTableRange(lines);
    final primaryLines = tableRange != null
        ? lines.sublist(tableRange.$1, tableRange.$2 + 1)
        : lines;

    final parsedPrimary = _parseCandidates(primaryLines);
    final parsedFallback = _parseCandidates(lines);
    final parsedLoose = _parseLoosePairing(lines);
    final parsedSeparated = _parseSeparatedNameAndTtColumns(lines);
    final parsedGenericPrimary = _parseSeparatedColumns(primaryLines);
    final parsedGenericAll = _parseSeparatedColumns(lines);

    final best = _pickBestResult([
      parsedPrimary,
      parsedFallback,
      parsedLoose,
      parsedSeparated,
      parsedGenericPrimary,
      parsedGenericAll,
    ]);

    return _deduplicate(best);
  }

  List<ReceiptOcrItem> _parseCandidates(List<String> lines) {
    final items = <ReceiptOcrItem>[];

    for (var i = 0; i < lines.length; i++) {
      final current = lines[i];
      final parsed = _parseCandidateLine(current);
      if (parsed != null) {
        items.add(parsed);
        continue;
      }

      if (i + 1 < lines.length) {
        final merged = _mergeIfSplitItemLine(current, lines[i + 1]);
        if (merged != null) {
          items.add(merged);
          i += 1;
        }
      }
    }

    return items;
  }

  List<ReceiptOcrItem> _parseLoosePairing(List<String> lines) {
    final items = <ReceiptOcrItem>[];
    String? pendingName;

    for (final line in lines) {
      final normalized = _normalizeForKeyword(line);
      if (_isBadContextLine(normalized)) {
        pendingName = null;
        continue;
      }

      final hasAmount = _hasAmountToken(line);
      if (!hasAmount) {
        final candidateName = _cleanItemName(line);
        if (_isValidItemName(candidateName)) {
          pendingName = candidateName;
        }
        continue;
      }

      final amountMatch = _lastAmountMatch(line);
      if (amountMatch == null) {
        continue;
      }

      final inlineName = _cleanItemName(line.substring(0, amountMatch.start).trim());
      final name = _isValidItemName(inlineName) ? inlineName : pendingName;
      if (name == null || !_isValidItemName(name)) {
        continue;
      }

      final amount = _parseAmount(amountMatch.group(0) ?? '');
      if (amount == null) {
        continue;
      }

      items.add(ReceiptOcrItem(name: name, amount: amount));
      pendingName = null;
    }

    return items;
  }

  List<ReceiptOcrItem> _parseSeparatedNameAndTtColumns(List<String> lines) {
    final names = <String>[];
    final ttAmounts = <double>[];

    var seenTtHeader = false;

    for (final line in lines) {
      final normalized = _normalizeForKeyword(line);

      if (normalized == 'tt') {
        seenTtHeader = true;
        continue;
      }

      if (!seenTtHeader) {
        final name = _cleanItemName(line);
        if (_isValidItemName(name)) {
          names.add(name);
        }
        continue;
      }

      if (_looksLikeItemTableFooter(normalized) || _isMetadataText(normalized)) {
        continue;
      }

      final amountMatch = _lastAmountMatch(line);
      if (amountMatch == null) {
        continue;
      }

      final amount = _parseAmount(amountMatch.group(0) ?? '');
      if (amount == null) {
        continue;
      }

      ttAmounts.add(amount);
    }

    if (names.isEmpty || ttAmounts.isEmpty) {
      return const [];
    }

    final itemCount = min(names.length, ttAmounts.length);
    if (itemCount == 0) {
      return const [];
    }

    final items = <ReceiptOcrItem>[];
    for (var i = 0; i < itemCount; i++) {
      items.add(ReceiptOcrItem(name: names[i], amount: ttAmounts[i]));
    }

    return items;
  }

  List<ReceiptOcrItem> _parseSeparatedColumns(List<String> lines) {
    final names = <String>[];
    final amounts = <double>[];

    for (final line in lines) {
      final normalized = _normalizeForKeyword(line);
      if (_isMetadataText(normalized) || _looksLikeItemTableFooter(normalized)) {
        continue;
      }

      final amountMatch = _lastAmountMatch(line);

      if (amountMatch != null) {
        final amount = _parseAmount(amountMatch.group(0) ?? '');
        if (amount != null && !_looksLikeItemTableHeader(normalized)) {
          amounts.add(amount);
        }

        final inlineName = _cleanItemName(line.substring(0, amountMatch.start).trim());
        if (_isValidItemName(inlineName)) {
          names.add(inlineName);
        }
        continue;
      }

      final nameOnly = _cleanItemName(line);
      if (_isValidItemName(nameOnly)) {
        names.add(nameOnly);
      }
    }

    final count = min(names.length, amounts.length);
    if (count == 0) {
      return const [];
    }

    final items = <ReceiptOcrItem>[];
    for (var i = 0; i < count; i++) {
      items.add(ReceiptOcrItem(name: names[i], amount: amounts[i]));
    }

    return items;
  }

  List<ReceiptOcrItem> _pickBestResult(List<List<ReceiptOcrItem>> candidates) {
    var best = const <ReceiptOcrItem>[];
    var bestScore = -1;

    for (final candidate in candidates) {
      final score = _scoreItems(candidate);
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }

    return best;
  }

  int _scoreItems(List<ReceiptOcrItem> items) {
    if (items.isEmpty) {
      return 0;
    }

    var score = items.length * 100;
    for (final item in items) {
      score += min(item.name.length, 20);
      if (item.amount >= 1000 && item.amount <= 5000000) {
        score += 10;
      }
    }

    return score;
  }

  ReceiptOcrItem? _mergeIfSplitItemLine(String current, String next) {
    final currentNormalized = _normalizeForKeyword(current);
    final nextNormalized = _normalizeForKeyword(next);

    if (_isBadContextLine(currentNormalized) || _isBadContextLine(nextNormalized)) {
      return null;
    }

    if (_hasAmountToken(current) || !_hasAmountToken(next)) {
      return null;
    }

    return _parseCandidateLine('$current $next');
  }

  ReceiptOcrItem? _parseCandidateLine(String rawLine) {
    final text = _sanitizeLine(rawLine);
    if (text.isEmpty) {
      return null;
    }

    final normalized = _normalizeForKeyword(text);
    if (_isBadContextLine(normalized)) {
      return null;
    }

    final amountMatch = _lastAmountMatch(text);
    if (amountMatch == null) {
      return null;
    }

    final rawAmount = amountMatch.group(0) ?? '';
    final namePart = text.substring(0, amountMatch.start).trim();
    final cleanedName = _cleanItemName(namePart);
    if (!_isValidItemName(cleanedName)) {
      return null;
    }

    final amount = _parseAmount(rawAmount);
    if (amount == null) {
      return null;
    }

    return ReceiptOcrItem(name: cleanedName, amount: amount);
  }

  (int, int)? _findTableRange(List<String> lines) {
    var headerIndex = -1;
    for (var i = 0; i < lines.length; i++) {
      final normalized = _normalizeForKeyword(lines[i]);
      if (_looksLikeItemTableHeader(normalized)) {
        headerIndex = i;
        break;
      }
    }

    if (headerIndex == -1) {
      return null;
    }

    var footerIndex = lines.length - 1;
    for (var i = headerIndex + 1; i < lines.length; i++) {
      final normalized = _normalizeForKeyword(lines[i]);
      if (_looksLikeItemTableFooter(normalized)) {
        footerIndex = i - 1;
        break;
      }
    }

    if (footerIndex <= headerIndex) {
      return null;
    }

    return (headerIndex + 1, footerIndex);
  }

  String _sanitizeLine(String line) {
    return line
        .replaceAll('|', 'I')
        .replaceAll('—', '-')
        .replaceAll(':', ' ')
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'[\t]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeForKeyword(String value) {
    return _foldVietnamese(value.toLowerCase())
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalizeAmountToken(String value) {
    return value
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('S', '5')
        .replaceAll('s', '5')
        .replaceAll('Z', '2')
        .replaceAll('z', '2');
  }

  String _cleanItemName(String rawName) {
    var name = rawName
        .replaceAll(RegExp(r'^[0-9]{1,3}[\)\.-]?\s+'), '')
        .replaceAll(RegExp(r'^[xX]\s+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    name = name.replaceFirst(RegExp(r'\s+[0-9\.,OoIlSsZz]{3,}\s*$'), '').trim();
    name = name.replaceFirst(RegExp(r'\s+[0-9]{1,3}\s*$'), '').trim();

    return name;
  }

  String _foldVietnamese(String input) {
    return input
        .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
        .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
        .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
        .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
        .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
        .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
        .replaceAll(RegExp(r'[đ]'), 'd');
  }

  bool _containsAny(String input, List<String> keywords) {
    for (final keyword in keywords) {
      if (input.contains(keyword)) {
        return true;
      }
    }
    return false;
  }

  bool _isMetadataText(String normalizedInput) {
    return _containsAny(normalizedInput, _metadataKeywords) ||
        normalizedInput.contains('so h0') ||
        normalizedInput.contains('so ho') ||
        normalizedInput.contains('thanh toan tien mat') ||
        _isInvoiceIdLikeLine(normalizedInput);
  }

  bool _isInvoiceIdLikeLine(String normalizedInput) {
    if (RegExp(r'\bs[o0]\s*h[d0o]\b').hasMatch(normalizedInput)) {
      return true;
    }

    if (RegExp(r'\bm[a4]\s*h[d0o]\b').hasMatch(normalizedInput)) {
      return true;
    }

    return false;
  }

  bool _isBadContextLine(String normalizedInput) {
    if (_isMetadataText(normalizedInput)) {
      return true;
    }

    if (_looksLikeDateOrTimeLine(normalizedInput)) {
      return true;
    }

    if (_looksLikeItemTableHeader(normalizedInput) ||
        _looksLikeItemTableFooter(normalizedInput)) {
      return true;
    }

    return false;
  }

  bool _hasAmountToken(String line) {
    return _amountTokenPattern.hasMatch(line);
  }

  bool _isGenericBadName(String normalizedName) {
    const badNames = <String>{
      'tien',
      'hoa don',
      'thanh toan',
      'powered by ipos.vn',
      'powered by ipos',
      'ipos.vn',
      'don gia sl',
      'sl don gia',
    };

    final name = normalizedName.trim();
    if (badNames.contains(name)) {
      return true;
    }

    if (RegExp(r'\bso\s*h[d0]\b').hasMatch(name) || RegExp(r'^h[d0]\s*:?$').hasMatch(name)) {
      return true;
    }

    if (RegExp(r'^(d\s*gia|dgia|sl|tt)(\s+(d\s*gia|dgia|sl|tt))*$').hasMatch(name)) {
      return true;
    }

    return false;
  }

  RegExpMatch? _lastAmountMatch(String text) {
    final matches = _amountTokenPattern.allMatches(text).toList();
    if (matches.isEmpty) {
      return null;
    }
    return matches.last;
  }

  double? _parseAmount(String rawAmount) {
    final normalizedAmount = _normalizeAmountToken(rawAmount);
    final digitsOnly = normalizedAmount.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) {
      return null;
    }

    final amount = double.tryParse(digitsOnly);
    if (amount == null) {
      return null;
    }

    if (amount < 100 || amount > 100000000) {
      return null;
    }

    if (amount >= 1900 && amount <= 2100) {
      return null;
    }

    return amount;
  }

  bool _isValidItemName(String name) {
    if (name.length < 2) {
      return false;
    }

    if (!RegExp(r'[A-Za-z0-9\u00C0-\u1EF9]').hasMatch(name)) {
      return false;
    }

    final normalized = _normalizeForKeyword(name);
    if (_isMetadataText(normalized) || _isGenericBadName(normalized)) {
      return false;
    }

    if (_containsAny(normalized, _headerKeywords) || _containsAny(normalized, _footerKeywords)) {
      return false;
    }

    final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();
    final hasMeaningfulWord = words.any((w) => w.length >= 2 && RegExp(r'[a-z]').hasMatch(w));
    if (!hasMeaningfulWord) {
      return false;
    }

    return true;
  }

  bool _looksLikeItemTableHeader(String normalizedLine) {
    if (normalizedLine.contains('tt ten mon')) {
      return true;
    }

    final hasName = normalizedLine.contains('ten mon') || normalizedLine.contains('ten hang');
    final hasPrice = normalizedLine.contains('don gia') ||
        normalizedLine.contains('d gia') ||
        normalizedLine.contains('dgia');
    final hasTotal = normalizedLine.contains('thanh tien') || normalizedLine.contains('tt');
    final hasQty = normalizedLine.contains('sl') || normalizedLine.contains('so luong');

    return (hasName && (hasPrice || hasTotal || hasQty)) || ((hasPrice || hasQty) && hasTotal);
  }

  bool _looksLikeItemTableFooter(String normalizedLine) {
    return _containsAny(normalizedLine, _footerKeywords);
  }

  bool _looksLikeDateOrTimeLine(String normalizedInput) {
    return _dateOrTimePattern.hasMatch(normalizedInput);
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
