import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/event_repository.dart';
import 'screens/calendar_screen.dart';
import 'state/calendar_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // без этого intl не знает русских названий месяцев и дней недели
  await initializeDateFormatting('ru_RU');

  // CalendarScreen -> CalendarState -> EventRepository
  CalendarState state = CalendarState(EventRepository());
  runApp(CalendarApp(state: state));
}

class CalendarApp extends StatelessWidget {
  final CalendarState state;

  const CalendarApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Календарь',
      debugShowCheckedModeBanner: false,
      // русский язык для выбора даты и времени (showDatePicker, showTimePicker)
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      home: CalendarScreen(state: state),
    );
  }
}
