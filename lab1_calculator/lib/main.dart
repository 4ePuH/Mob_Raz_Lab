import 'package:flutter/material.dart';

import 'screens/calculator_screen.dart';

void main() {
  runApp(const CalculatorApp());
}

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFF1C1C1E);

    return MaterialApp(
      title: 'Калькулятор',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.orange,
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(backgroundColor: background),
      ),
      home: const CalculatorScreen(),
    );
  }
}
