import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ebook/screens/splash_screen.dart';
import 'package:ebook/screens/login_screen.dart';
import 'package:ebook/screens/home_screen.dart';
import 'package:ebook/screens/settings_screen.dart';
import 'package:ebook/screens/book_details_screen.dart';
import 'package:ebook/screens/reader_screen.dart';
import 'package:ebook/screens/my_library_screen.dart';

import 'package:ebook/screens/forgot_password_screen.dart';
import 'package:ebook/screens/for_you_screen.dart'; // Ensure this is imported
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Book Nest',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/for_you': (context) => const ForYouScreen(), // Explicit route
        '/settings': (context) => const SettingsScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/library': (context) => const MyLibraryScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle Book Details Screen
        if (settings.name == '/book_details') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};

          return MaterialPageRoute(
            builder: (context) => BookDetailsScreen(
              bookKey: args['key']?.toString() ?? "", // Ensure string type
              title: args['title']?.toString() ?? "No Title",
              cover: args['cover']?.toString() ?? "",
            ),
          );
        }

        // Handle Reader Screen
        if (settings.name == '/reader') {
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          return MaterialPageRoute(
            builder: (context) => ReaderScreen(
              bookKey: args['key']?.toString() ?? "",
            ),
          );
        }

        return null;
      },
    );
  }
}