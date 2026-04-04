import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

Future<String> extractTextWithWebTesseract(String imagePath) async {
  final tesseractJs = web.window.getProperty('Tesseract'.toJS);
  if (tesseractJs == null) {
    throw Exception('Tesseract.js chưa được nạp trên web/index.html');
  }

  final recognize = (tesseractJs as JSObject).getProperty('recognize'.toJS);
  final promise = (recognize as JSFunction).callAsFunction(
    tesseractJs as JSAny,
    imagePath.toJS,
    'eng+vie'.toJS,
  ) as JSPromise;

  final result = await promise.toDart;
  final resultMap = result.dartify();

  if (resultMap is! Map) {
    throw Exception('Kết quả OCR web không hợp lệ.');
  }

  final data = resultMap['data'];
  if (data is! Map) {
    throw Exception('Kết quả OCR web thiếu trường data.');
  }

  final text = data['text'];

  return text?.toString() ?? '';
}
