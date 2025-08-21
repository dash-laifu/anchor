import 'package:flutter/material.dart';
import 'package:anchor/theme.dart';
import 'package:anchor/screens/home_screen.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() {
  // Initialize timezone data for notifications
  tz.initializeTimeZones();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anchor - Parking Saver',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
