import 'package:barber_booking/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static const bool _useEmulator = bool.fromEnvironment(
    'FIREBASE_USE_EMULATOR',
    defaultValue: false,
  );

  static const String _emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '127.0.0.1',
  );

  static Future<void> initFirebase() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      if (_useEmulator) {
        await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);

        FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);

        if (kDebugMode) {
          // ignore: avoid_print
          print(
            'Firebase Emulators connected: '
            '$_emulatorHost '
            '(Auth: 9099, Firestore: 8080)',
          );
        }
      } else {
        if (kDebugMode) {
          // ignore: avoid_print
          print('Firebase initialized');
        }
      }
    } catch (e, st) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Failed to initialize Firebase: $e\n$st');
      }

      rethrow;
    }
  }
}
