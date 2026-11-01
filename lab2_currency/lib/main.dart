import 'package:flutter/material.dart';

import 'data/cbr_api_client.dart';
import 'data/currency_repository.dart';
import 'data/favorites_storage.dart';
import 'screens/converter_screen.dart';
import 'state/converter_state.dart';

void main() {
  // цепочка как в задании: UI -> ConverterState -> CurrencyRepository -> ApiClient
  ConverterState state = ConverterState(
    repository: CurrencyRepository(CbrApiClient()),
    favoritesStorage: FavoritesStorage(),
  );
  runApp(ConverterApp(state: state));
}

class ConverterApp extends StatelessWidget {
  final ConverterState state;

  const ConverterApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Конвертер валют',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.teal,
        brightness: Brightness.dark,
      ),
      home: ConverterScreen(state: state),
    );
  }
}
