import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
    apiKey: 'dummy_web_api_key',
    appId: '1:1234567890:web:dummy12345',
    messagingSenderId: '1234567890',
    projectId: 'quickbite-dummy',
    authDomain: 'quickbite-dummy.firebaseapp.com',
    storageBucket: 'quickbite-dummy.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'dummy_android_api_key',
    appId: '1:1234567890:android:dummy12345',
    messagingSenderId: '1234567890',
    projectId: 'quickbite-dummy',
    storageBucket: 'quickbite-dummy.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy_ios_api_key',
    appId: '1:1234567890:ios:dummy12345',
    messagingSenderId: '1234567890',
    projectId: 'quickbite-dummy',
    storageBucket: 'quickbite-dummy.appspot.com',
    iosBundleId: 'com.quickbite.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy_macos_api_key',
    appId: '1:1234567890:ios:dummy12345',
    messagingSenderId: '1234567890',
    projectId: 'quickbite-dummy',
    storageBucket: 'quickbite-dummy.appspot.com',
    iosBundleId: 'com.quickbite.app.macos',
  );
}
