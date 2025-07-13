import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard.dart';
import 'edit_id_screen.dart';
import 'screen/add_id_screen.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return MaterialApp(
      title: 'OneID Nigeria',
      theme: ThemeData(primarySwatch: Colors.teal),
      debugShowCheckedModeBanner: false,
      home: user == null ? const LoginScreen() : const DashboardScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/addId': (context) => AddIDScreen(userId: FirebaseAuth.instance.currentUser?.uid ?? ''),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/editId') {
          final idKey = settings.arguments as String;
          return MaterialPageRoute(
            builder: (context) => EditIDScreen(idKey: idKey),
          );
        }
        return null;
      },
    );
  }
}
