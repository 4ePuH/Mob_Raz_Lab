import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../models/weather_code.dart';
import '../utils/format.dart';

class CurrentWeatherCard extends StatelessWidget {
  final Weather weather;

  const CurrentWeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    TextTheme text = Theme.of(context).textTheme;
    CurrentWeather c = weather.current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              weather.city.title,
              style: text.titleLarge,
              textAlign: TextAlign.center,
            ),
            if (weather.city.region.isNotEmpty &&
                weather.city.region != weather.city.name)
              Text(weather.city.region, style: text.bodySmall),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(weatherIcon(c.weatherCode), size: 56),
                const SizedBox(width: 16),
                Text(formatTemp(c.temperature), style: text.displayMedium),
              ],
            ),
            Text(weatherDescription(c.weatherCode), style: text.titleMedium),
            Text('Ощущается как ${formatTemp(c.feelsLike)}'),
            const Divider(height: 32),
            // Wrap: на узком экране показатели переносятся, а не вылезают
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 12,
              children: [
                _Stat(
                  icon: Icons.water_drop_outlined,
                  label: 'Влажность',
                  value: '${c.humidity}%',
                ),
                _Stat(
                  icon: Icons.air,
                  label: 'Ветер',
                  value: '${c.windSpeed.toStringAsFixed(1)} м/с',
                ),
                if (c.pressureMmHg != null)
                  _Stat(
                    icon: Icons.speed,
                    label: 'Давление',
                    value: '${c.pressureMmHg} мм рт. ст.',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
