class AiLocalConfig {
  const AiLocalConfig._();

  // WARNING: This key is intentionally local-in-repo per project requirement.
  // Replace with your real Gemini API key before running chat.
  static const String _placeholderKey = 'PASTE_YOUR_GEMINI_API_KEY_HERE';
  static const String geminiApiKey = 'AIzaSyCI-JAPFjHzqh6iYo0VIN_C5pilRcWZ-Rk';

  static bool get hasValidKey {
    return geminiApiKey.isNotEmpty && geminiApiKey != _placeholderKey;
  }
}
