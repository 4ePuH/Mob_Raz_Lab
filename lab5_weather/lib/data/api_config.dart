// Адреса API вынесены сюда, в интерфейсе их нет.
// Open-Meteo бесплатный и без ключа. Если бы ключ был нужен,
// его брали бы через --dart-define, а не писали в код
class ApiConfig {
  static const String geocodingUrl =
      'https://geocoding-api.open-meteo.com/v1/search';
  static const String forecastUrl = 'https://api.open-meteo.com/v1/forecast';

  static const Duration timeout = Duration(seconds: 10);
  static const int forecastDays = 7;
}
