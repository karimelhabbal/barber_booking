import 'dart:io';

import 'package:flutter/foundation.dart';

void main() {
  final root = Directory.current.path;
  final eol = '\r\n';

  String normalize(String s) {
    // Strip CR and normalize all line endings to LF.
    return s.replaceAll('\r', '');
  }

  // ---- main.dart ----
  final mainPath = '$root/lib/main.dart';
  var main = File(mainPath).readAsStringSync();
  main = main
      .replaceAll(
        "import 'package:barber_booking/core/services/firebase_service.dart';$eol",
        '',
      )
      .replaceAll(
        "import 'package:firebase_messaging/firebase_messaging.dart';$eol",
        '',
      )
      .replaceAll('  await FirebaseService.initFirebase();$eol', '')
      .replaceAll(
        '    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);$eol',
        '',
      )
      .replaceAll(RegExp('import $eol', caseSensitive: false), '');
  main = normalize(main);
  File(mainPath).writeAsStringSync(main);

  // ---- injection.dart ----
  final injPath = '$root/lib/core/di/injection.dart';
  var inj = File(injPath).readAsStringSync();
  inj = inj
      .replaceAll(
        "import 'package:cloud_firestore/cloud_firestore.dart';$eol",
        '',
      )
      .replaceAll(
        "import 'package:cloud_functions/cloud_functions.dart';$eol",
        '',
      )
      .replaceAll(
        "import 'package:firebase_auth/firebase_auth.dart' as fb;$eol",
        '',
      )
      .replaceAll(
        "import 'package:firebase_messaging/firebase_messaging.dart';$eol",
        '',
      );
  inj = inj.replaceAll(
    '  getIt.registerLazySingleton<fb.FirebaseAuth>(() => fb.FirebaseAuth.instance);$eol',
    '',
  );
  inj = inj
      .replaceAll('  getIt.registerLazySingleton<FirebaseFirestore>($eol', '')
      .replaceAll('    () => FirebaseFirestore.instance,$eol', '');
  inj = normalize(inj);
  File(injPath).writeAsStringSync(inj);

  // ---- pubspec.yaml ----
  final pubPath = '$root/pubspec.yaml';
  var pub = File(pubPath).readAsStringSync();
  pub = pub
      .replaceAll('  firebase_core: ^4.14.0$eol', '')
      .replaceAll('  firebase_auth: ^6.5.0$eol', '')
      .replaceAll('  cloud_firestore: ^6.8.0$eol', '')
      .replaceAll('  firebase_messaging: ^16.7.0$eol', '')
      .replaceAll('  cloud_functions: ^6.0.0$eol', '');
  pub = normalize(pub);
  File(pubPath).writeAsStringSync(pub);

  // ---- Android plugin registrant ----
  final androidPath =
      '$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java';
  var android = File(androidPath).readAsStringSync();
  android = android
      .replaceAll(
        '    try {$eol      flutterEngine.getPlugins().add(new com.llfbandit.app_links.AppLinksPlugin());$eol    } catch (Exception e) {$eol      Log.e(TAG, "Error registering plugin app_links, com.llfbandit.app_links.AppLinksPlugin", e);$eol    }$eol',
        '',
      )
      .replaceAll(
        '    try {$eol      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin());$eol    } catch (Exception e) {$eol      Log.e(TAG, "Error registering plugin cloud_firestore, io.flutter.plugins.firebase.firestore.FlutterFirebaseFirestorePlugin", e);$eol    }$eol',
        '',
      )
      .replaceAll(
        '    try {$eol      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.functions.FlutterFirebaseFunctionsPlugin());$eol    } catch (Exception e) {$eol      Log.e(TAG, "Error registering plugin cloud_functions, io.flutter.plugins.firebase.functions.FlutterFirebaseFunctionsPlugin", e);$eol    }$eol',
        '',
      )
      .replaceAll(
        '    try {$eol      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin());$eol    } catch (Exception e) {$eol      Log.e(TAG, "Error registering plugin firebase_auth, io.flutter.plugins.firebase.auth.FlutterFirebaseAuthPlugin", e);$eol    }$eol',
        '',
      )
      .replaceAll(
        '    try {$eol      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin());$eol    } catch (Exception e) {$eol      Log.e(TAG, "Error registering plugin firebase_core, io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin", e);$eol    }$eol',
        '',
      )
      .replaceAll(
        '    try {$eol      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin());$eol    } catch (Exception e) {$eol      Log.e(TAG, "Error registering plugin firebase_messaging, io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin", e);$eol    }$eol',
        '',
      );
  android = normalize(android);
  File(androidPath).writeAsStringSync(android);

  // ---- macOS plugin registrant ----
  final macosPath = '$root/macos/Flutter/GeneratedPluginRegistrant.swift';
  var macos = File(macosPath).readAsStringSync();
  macos = macos
      .replaceAll('import cloud_firestore$eol', '')
      .replaceAll('import cloud_functions$eol', '')
      .replaceAll('import firebase_auth$eol', '')
      .replaceAll('import firebase_core$eol', '')
      .replaceAll('import firebase_messaging$eol', '');
  macos = macos
      .replaceAll(
        '  FLTFirebaseFirestorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseFirestorePlugin"))$eol',
        '',
      )
      .replaceAll(
        '  FirebaseFunctionsPlugin.register(with: registry.registrar(forPlugin: "FirebaseFunctionsPlugin"))$eol',
        '',
      )
      .replaceAll(
        '  FLTFirebaseAuthPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseAuthPlugin"))$eol',
        '',
      )
      .replaceAll(
        '  FLTFirebaseCorePlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseCorePlugin"))$eol',
        '',
      )
      .replaceAll(
        '  FLTFirebaseMessagingPlugin.register(with: registry.registrar(forPlugin: "FLTFirebaseMessagingPlugin"))$eol',
        '',
      );
  macos = normalize(macos);
  File(macosPath).writeAsStringSync(macos);

  if (kDebugMode) {
    print('Firebase cleanup complete.');
  }
}
