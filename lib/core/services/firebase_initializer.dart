import 'package:firebase_core/firebase_core.dart';

import 'package:expensetracker/firebase_options.dart';

class FirebaseInitializer {
  const FirebaseInitializer._();

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } on UnsupportedError {
      // Fallback for platforms not configured by FlutterFire.
      await Firebase.initializeApp();
    }
  }
}
