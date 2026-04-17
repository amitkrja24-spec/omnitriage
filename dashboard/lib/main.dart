import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // ADD THIS
import 'package:flutter/foundation.dart'; // ADD THIS
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'screens/coordinator_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ── EMULATOR CONNECTION ──
  // This tells the app to talk to your laptop, not the internet
  if (kDebugMode) {
    try {
      // 8080 is the default port for the Firestore emulator
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      print("✅ Connected to Local Firestore Emulator");
    } catch (e) {
      print("❌ Error connecting to emulator: $e");
    }
  }
  // ─────────────────────────

  runApp(const OmniTriageApp());
}

class OmniTriageApp extends StatelessWidget {
  const OmniTriageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniTriage',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const CoordinatorDashboard(),
    );
  }
}
