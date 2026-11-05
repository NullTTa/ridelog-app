import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() {
  runApp(const RideLogApp());
}

class RideLogApp extends StatelessWidget {
  const RideLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideLog',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFE8590C)),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
