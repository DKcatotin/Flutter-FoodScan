import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_scan_flutter/screens/api_test_scren.dart';
import 'package:food_scan_flutter/screens/profile_screen.dart';
import 'package:food_scan_flutter/screens/scan_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Scan',
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),      // <- Sin const aquí
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/scan': (context) => ScanScreen(),
    //'/history': (context) => HistoryScreen()
        '/api-test': (context) => ApiTestScreen(),
      },
    );
  }
}
