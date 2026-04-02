class AiLocalConfig {
  const AiLocalConfig._();

  // WARNING: This key is intentionally local-in-repo per project requirement.
  // Replace with your real Gemini API key before running chat.
  static const String _placeholderKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';
  static const String geminiApiKey = 'AIzaSyAIulA8ZgrO75Iv0Uc0HIM00aX7nRdkDQA';

  static bool get hasValidKey {
    return geminiApiKey.isNotEmpty && geminiApiKey != _placeholderKey;
  }
}
