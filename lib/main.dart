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
      storageBucket: "bookrecapp-6d7ab.appspot.com", // Fixed typo here
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
        primarySwatch: Colors.blue,
      ),
      home: const LoginScreen(), // Start at login
    );
  }
}
