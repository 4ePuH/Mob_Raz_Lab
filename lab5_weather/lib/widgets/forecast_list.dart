import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../models/weather_code.dart';
import '../utils/format.dart';

class ForecastList extends StatelessWidget {
  final List<DailyForecast> days;

  const ForecastList({super.key, required this.days});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              'Прогноз на ${days.length} ${daysWord(days.length)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (int i = 0; i < days.length; i++)
            ListTile(
              leading: Icon(weatherIcon(days[i].weatherCode)),
              // первый день в ответе - сегодня
              title: Text(i == 0 ? 'Сегодня' : formatDay(days[i].date)),
              subtitle: Text(weatherDescription(days[i].weatherCode)),
              trailing: Text(
                '${formatTemp(days[i].maxTemp)} / ${formatTemp(days[i].minTemp)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
        ],
      ),
    );
  }
}
