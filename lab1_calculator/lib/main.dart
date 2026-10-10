import 'package:flutter/material.dart';

import 'screens/calculator_screen.dart';

void main() {
  runApp(const CalculatorApp());
}

// StatefulWidget, потому что тема меняется во время работы
class CalculatorApp extends StatefulWidget {
  const CalculatorApp({super.key});

  @override
  State<CalculatorApp> createState() => _CalculatorAppState();
}

class _CalculatorAppState extends State<CalculatorApp> {
  // по умолчанию тёмная, как на картинке в задании
  bool isDark = true;

  void toggleTheme() {
    setState(() {
      isDark = !isDark;
    });
  }

  @override
  Widget build(BuildContext context) {
    const darkBackground = Color(0xFF1C1C1E);
    const lightBackground = Color(0xFFF2F2F7);

    return MaterialApp(
      title: 'Калькулятор',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.orange,
        scaffoldBackgroundColor: lightBackground,
        appBarTheme: const AppBarTheme(backgroundColor: lightBackground),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.orange,
        scaffoldBackgroundColor: darkBackground,
        appBarTheme: const AppBarTheme(backgroundColor: darkBackground),
      ),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: CalculatorScreen(isDark: isDark, onThemeChanged: toggleTheme),
    );
  }
}
