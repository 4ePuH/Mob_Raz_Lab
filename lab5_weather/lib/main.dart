import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/weather_api_client.dart';
import 'data/weather_cache.dart';
import 'data/weather_repository.dart';
import 'screens/weather_screen.dart';
import 'state/weather_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // русские названия дней недели для прогноза
  await initializeDateFormatting('ru');

  // WeatherScreen -> WeatherState -> WeatherRepository -> WeatherApiClient
  WeatherState state = WeatherState(
    WeatherRepository(api: WeatherApiClient(), cache: WeatherCache()),
  );
  runApp(WeatherApp(state: state));
}

class WeatherApp extends StatelessWidget {
  final WeatherState state;

  const WeatherApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Погода',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.lightBlue),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.lightBlue,
        brightness: Brightness.dark,
      ),
      home: WeatherScreen(state: state),
    );
  }
}
