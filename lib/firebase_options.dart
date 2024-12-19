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
    apiKey: 'AIzaSyCBDjSCG_NBbv5Q3z5611gzItKDt3t_EIg',
    appId: '1:675510344722:web:eb1babd075ace619214ccb',
    messagingSenderId: '675510344722',
    projectId: 'cloud-task1-9c8e8',
    authDomain: 'cloud-task1-9c8e8.firebaseapp.com',
    storageBucket: 'cloud-task1-9c8e8.firebasestorage.app',
    measurementId: 'G-EGYHLRMF5V',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD-Jn9AoaCuCGp-Oj2Iqm301y2Q8_F1a0A',
    appId: '1:675510344722:android:bfd75929db5a2a93214ccb',
    messagingSenderId: '675510344722',
    projectId: 'cloud-task1-9c8e8',
    storageBucket: 'cloud-task1-9c8e8.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBmqUIZ2kTw-3dwZQijhZ1M-LsgKc8M9KI',
    appId: '1:675510344722:ios:9a5d2f32bafa64a3214ccb',
    messagingSenderId: '675510344722',
    projectId: 'cloud-task1-9c8e8',
    storageBucket: 'cloud-task1-9c8e8.firebasestorage.app',
    iosBundleId: 'com.example.myApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBmqUIZ2kTw-3dwZQijhZ1M-LsgKc8M9KI',
    appId: '1:675510344722:ios:9a5d2f32bafa64a3214ccb',
    messagingSenderId: '675510344722',
    projectId: 'cloud-task1-9c8e8',
    storageBucket: 'cloud-task1-9c8e8.firebasestorage.app',
    iosBundleId: 'com.example.myApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCBDjSCG_NBbv5Q3z5611gzItKDt3t_EIg',
    appId: '1:675510344722:web:f0f14de53220b967214ccb',
    messagingSenderId: '675510344722',
    projectId: 'cloud-task1-9c8e8',
    authDomain: 'cloud-task1-9c8e8.firebaseapp.com',
    storageBucket: 'cloud-task1-9c8e8.firebasestorage.app',
    measurementId: 'G-T8YKVBPLQ0',
  );
}