class AiLocalConfig {
  const AiLocalConfig._();

 
  // flutter run --dart-define=GEMINI_API_KEY=your_key
  // flutter build apk --debug --dart-define=GEMINI_API_KEY=your_key
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');

  static bool get hasValidKey {
    return geminiApiKey.trim().isNotEmpty;
  }
}
