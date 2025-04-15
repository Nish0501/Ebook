// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBPrqkddwm7OpP_4ekXOBWmBWPajlY8xJE',
    appId: '1:575205014568:web:092c9fe25d3c19510d091d',
    messagingSenderId: '575205014568',
    projectId: 'booknest-f29ee',
    authDomain: 'booknest-f29ee.firebaseapp.com',
    storageBucket: 'booknest-f29ee.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCoK6gnTSFU31uyHR7obZGi8ABNEiL95d0',
    appId: '1:575205014568:android:fa2b426fc51b81de0d091d',
    messagingSenderId: '575205014568',
    projectId: 'booknest-f29ee',
    storageBucket: 'booknest-f29ee.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBAYjubU-vYW0lcGI7KML0RkBzDFBQ-OBg',
    appId: '1:575205014568:ios:a2c259f4bc6cb4c00d091d',
    messagingSenderId: '575205014568',
    projectId: 'booknest-f29ee',
    storageBucket: 'booknest-f29ee.firebasestorage.app',
    iosClientId: '575205014568-cuhes4fl7bbfdoa54081t8tm391da45s.apps.googleusercontent.com',
    iosBundleId: 'com.example.ebookk',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBAYjubU-vYW0lcGI7KML0RkBzDFBQ-OBg',
    appId: '1:575205014568:ios:a2c259f4bc6cb4c00d091d',
    messagingSenderId: '575205014568',
    projectId: 'booknest-f29ee',
    storageBucket: 'booknest-f29ee.firebasestorage.app',
    iosClientId: '575205014568-cuhes4fl7bbfdoa54081t8tm391da45s.apps.googleusercontent.com',
    iosBundleId: 'com.example.ebookk',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPrqkddwm7OpP_4ekXOBWmBWPajlY8xJE',
    appId: '1:575205014568:web:c1086acbf7a4375d0d091d',
    messagingSenderId: '575205014568',
    projectId: 'booknest-f29ee',
    authDomain: 'booknest-f29ee.firebaseapp.com',
    storageBucket: 'booknest-f29ee.firebasestorage.app',
  );
}
