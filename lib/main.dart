import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/home_screen.dart';
import 'screens/conversation_screen.dart';
import 'screens/login_screen.dart';
import 'screens/questionnaire_screen.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for local storage
  await Hive.initFlutter();
  await Firebase.initializeApp();
  // Open a box to store conversations
  await Hive.openBox('conversations');
  await Hive.openBox('userProfile');

  runApp(const DatingAssistantApp());
}

class DatingAssistantApp extends StatelessWidget {
  const DatingAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dating AI Assistant',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/questionnaire': (context) => const QuestionnaireScreen(),
        '/': (context) => const HomeScreen(),
        '/conversation': (context) => const ConversationScreen(),
      },
    );
  }
}