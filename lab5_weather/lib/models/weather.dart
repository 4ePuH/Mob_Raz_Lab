import 'city.dart';

class CurrentWeather {
  final double temperature;
  final double feelsLike;
  final int humidity;
  // м/с, в запросе указан wind_speed_unit=ms
  final double windSpeed;
  // гПа, может и не прийти
  final double? pressure;
  final int weatherCode;

  const CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.weatherCode,
  });

  // у нас привычнее мм рт. ст., 1 гПа = 0.750062 мм рт. ст.
  int? get pressureMmHg => pressure == null ? null : (pressure! * 0.750062).round();

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      feelsLike: (json['apparent_temperature'] as num).toDouble(),
      humidity: (json['relative_humidity_2m'] as num).round(),
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      pressure: (json['surface_pressure'] as num?)?.toDouble(),
      weatherCode: (json['weather_code'] as num).toInt(),
    );
  }
}

class DailyForecast {
  final DateTime date;
  final int weatherCode;
  final double minTemp;
  final double maxTemp;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.minTemp,
    required this.maxTemp,
  });
}

// Всё, что показываем на экране для одного города
class Weather {
  final City city;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  // когда данные получены с сервера (для кэша важно)
  final DateTime loadedAt;
  // true - сети нет, показываем сохранённое
  final bool fromCache;

  const Weather({
    required this.city,
    required this.current,
    required this.daily,
    required this.loadedAt,
    this.fromCache = false,
  });

  // json - ответ /v1/forecast целиком
  factory Weather.fromJson(
    Map<String, dynamic> json,
    City city, {
    required DateTime loadedAt,
    bool fromCache = false,
  }) {
    Map<String, dynamic> daily = json['daily'] as Map<String, dynamic>;
    // в daily не список объектов, а несколько списков одной длины:
    // time[i], weather_code[i], max[i], min[i] относятся к одному дню
    List<dynamic> times = daily['time'] as List<dynamic>;
    List<dynamic> codes = daily['weather_code'] as List<dynamic>;
    List<dynamic> maxs = daily['temperature_2m_max'] as List<dynamic>;
    List<dynamic> mins = daily['temperature_2m_min'] as List<dynamic>;

    List<DailyForecast> days = [];
    for (int i = 0; i < times.length; i++) {
      days.add(DailyForecast(
        date: DateTime.parse(times[i] as String),
        weatherCode: (codes[i] as num).toInt(),
        maxTemp: (maxs[i] as num).toDouble(),
        minTemp: (mins[i] as num).toDouble(),
      ));
    }

    return Weather(
      city: city,
      current: CurrentWeather.fromJson(json['current'] as Map<String, dynamic>),
      daily: days,
      loadedAt: loadedAt,
      fromCache: fromCache,
    );
  }
}
