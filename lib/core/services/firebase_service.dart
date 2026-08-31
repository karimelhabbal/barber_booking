import 'package:barber_booking/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  /// Initialize Firebase. Call this early in main().
  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      if (kDebugMode) {
        // ignore: avoid_print
        print('Firebase initialized');
      }
    } catch (e, st) {
      // Surface a clear message without crashing the app here; rethrow so callers can handle.
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to initialize Firebase: $e\n$st');
      }
      rethrow;
    }
  }
}
