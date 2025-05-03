import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/search_screen.dart';
import 'screens/book_details_screen.dart';
import 'screens/discussion_screen.dart';
import 'widgets/bottom_nav_bar.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBR13XQ6fnYo74V95usQhwUxwg4HKfvAxQ",
      authDomain: "bookrecapp-6d7ab.firebaseapp.com",
      projectId: "bookrecapp-6d7ab",
      storageBucket: "bookrecapp-6d7ab.appspot.com",
      messagingSenderId: "979329731515",
      appId: "1:979329731515:web:5995d4be0159cd8a76d29e",
    ),
  );
  runApp(const BookRecommendationApp());
}

class BookRecommendationApp extends StatelessWidget {
  const BookRecommendationApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Book Recommendation App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF5D4037), 
        scaffoldBackgroundColor: const Color(0xFF3E2723), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF4E342E),
          foregroundColor: Color(0xFFF5F5DC), 
          iconTheme: IconThemeData(color: Color(0xFFF5F5DC)),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF4E342E),
          selectedItemColor: Color(0xFFF5F5DC), 
          unselectedItemColor: Color(0xFFBCAAA4), 
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6D4C41), 
            foregroundColor: const Color(0xFFF5F5DC), 
          ),
        ),
        cardColor: const Color(0xFF4E342E),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF5F5DC)),
          bodyLarge: TextStyle(color: Color(0xFFF5F5DC)),
          titleLarge: TextStyle(color: Color(0xFFF5F5DC), fontWeight: FontWeight.bold),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
