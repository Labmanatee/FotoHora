import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

// I will create these files in the next steps
import 'package:fotohora/screens/web_viewer.dart';
import 'package:fotohora/screens/mobile_ui.dart';
import 'package:fotohora/screens/registration_screen.dart';

// Assuming firebase_options.dart exists after user runs `flutterfire configure`
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Check if user is registered
  final prefs = await SharedPreferences.getInstance();
  final bool isRegistered = prefs.getBool('isRegistered') ?? false;

  runApp(MyApp(isRegistered: isRegistered));
}

class MyApp extends StatelessWidget {
  final bool isRegistered;

  const MyApp({super.key, required this.isRegistered});

  @override
  Widget build(BuildContext context) {
    // This is the root of your application.
    Widget home;

    if (kIsWeb) {
      // On web, always show the map viewer.
      home = const WebViewer();
    } else {
      // On mobile, show registration screen or main UI.
      home = isRegistered ? const MobileTrackerUI() : const RegistrationScreen();
    }

    return MaterialApp(
      title: 'Fotohora Tracker',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: home,
    );
  }
}
