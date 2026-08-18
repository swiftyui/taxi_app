import 'dart:async';
import 'package:TaxiApp/firebase_options.dart';
import 'package:TaxiApp/src/taxi_app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future main() async {
  runZonedGuarded<Future<void>>(() async {
    final app = await _initApp();
    runApp(app);
  }, (error, stack) => _onErrorReceived(error, stack));
}

Future<Widget> _initApp() async {
  WidgetsFlutterBinding.ensureInitialized();

  // change device layouts
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitDown,
    DeviceOrientation.portraitUp,
  ]);
  try {
    await setupFirebase();
  } catch (e, s) {
    debugPrint('[setupFirebase error] $e\n$s');
  }

  return TaxiApp();
}

Future<void> setupFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void _onErrorReceived(Object error, StackTrace stackTrace) {
  if (kIsWeb) {
    if (kDebugMode) {
      debugPrint('[Web Error] $error');
      debugPrint('[Web StackTrace] $stackTrace');
    }
    return;
  }
}
