import '../models/city.dart';
import '../models/weather.dart';
import 'weather_api_client.dart';
import 'weather_cache.dart';

class CityNotFoundException implements Exception {
  final String query;

  CityNotFoundException(this.query);
}

// Единая точка, откуда приложение берёт погоду.
// Экран не знает, что для этого нужно два запроса (город -> координаты -> прогноз)
// и что при отсутствии сети данные могут прийти из кэша
class WeatherRepository {
  final WeatherApiClient api;
  final WeatherCache cache;
  // в тестах подменяем, чтобы время загрузки было известно заранее
  final DateTime Function() now;

  WeatherRepository({
    required this.api,
    required this.cache,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  Future<Weather> getWeather(String query) async {
    String q = query.trim();
    try {
      List<dynamic> results = await api.searchCity(q);
      if (results.isEmpty) {
        throw CityNotFoundException(q);
      }
      City city = City.fromJson(results.first as Map<String, dynamic>);

      Map<String, dynamic> json =
          await api.fetchForecast(city.latitude, city.longitude);
      DateTime loadedAt = now();

      Weather weather;
      try {
        weather = Weather.fromJson(json, city, loadedAt: loadedAt);
      } catch (e) {
        throw ApiException('Не удалось разобрать ответ сервера');
      }

      await cache.save(
        query: q,
        city: city,
        forecastJson: json,
        loadedAt: loadedAt,
      );
      return weather;
    } on ApiException catch (e) {
      // нет сети - пробуем показать то, что загружали раньше
      if (e.noConnection) {
        Weather? cached = await cache.load(q);
        if (cached != null) return cached;
      }
      rethrow;
    }
  }

  Future<String?> lastCity() => cache.lastCity();
}
