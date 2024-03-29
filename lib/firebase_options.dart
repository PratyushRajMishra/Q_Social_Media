// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
    apiKey: 'AIzaSyA-IoBNlo_54etyCSPFB_mma4x8_fwBwBA',
    appId: '1:938455911566:web:8318c7ab98be0cbb0d8ddf',
    messagingSenderId: '938455911566',
    projectId: 'qsocialmedia-b446b',
    authDomain: 'qsocialmedia-b446b.firebaseapp.com',
    storageBucket: 'qsocialmedia-b446b.appspot.com',
    measurementId: 'G-4HWE5Z9XFZ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAARSeuIV0GupST762tlAJPiym_q4HmAyw',
    appId: '1:938455911566:android:1c999cc227fb447d0d8ddf',
    messagingSenderId: '938455911566',
    projectId: 'qsocialmedia-b446b',
    storageBucket: 'qsocialmedia-b446b.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDV4WvE8iZJiEHLFXVCOsV3dglUA11IjL4',
    appId: '1:938455911566:ios:ec6a772b562631b00d8ddf',
    messagingSenderId: '938455911566',
    projectId: 'qsocialmedia-b446b',
    storageBucket: 'qsocialmedia-b446b.appspot.com',
    iosBundleId: 'com.example.q',
  );
}
