import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';

// Ошибка, которую можно показать пользователю.
// noConnection - отдельно, чтобы репозиторий мог взять данные из кэша
class ApiException implements Exception {
  final String message;
  final bool noConnection;

  ApiException(this.message, {this.noConnection = false});

  @override
  String toString() => message;
}

// Только запросы к Open-Meteo и разбор кодов ответа. Возвращает сырой JSON
class WeatherApiClient {
  final http.Client client;

  WeatherApiClient({http.Client? client}) : client = client ?? http.Client();

  // поиск города по названию, вернёт список results (может быть пустым)
  Future<List<dynamic>> searchCity(String name) async {
    Uri uri = Uri.parse(ApiConfig.geocodingUrl).replace(queryParameters: {
      'name': name,
      'count': '1',
      'language': 'ru',
      'format': 'json',
    });
    Map<String, dynamic> json = await _get(uri);
    // если ничего не нашлось, ключа results в ответе просто нет
    return (json['results'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> fetchForecast(double lat, double lon) {
    Uri uri = Uri.parse(ApiConfig.forecastUrl).replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lon.toString(),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,surface_pressure',
      'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
      'timezone': 'auto',
      'wind_speed_unit': 'ms',
      'forecast_days': ApiConfig.forecastDays.toString(),
    });
    return _get(uri);
  }

  Future<Map<String, dynamic>> _get(Uri uri) async {
    http.Response response;
    try {
      response = await client.get(uri).timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw ApiException('Сервер не отвечает', noConnection: true);
    } catch (e) {
      throw ApiException('Нет подключения к интернету', noConnection: true);
    }

    switch (response.statusCode) {
      case 200:
        break;
      case 400:
        throw ApiException('Неверный запрос к серверу погоды');
      case 404:
        throw ApiException('Данные не найдены (404)');
      case 429:
        throw ApiException('Слишком много запросов, подождите минуту');
      default:
        if (response.statusCode >= 500) {
          throw ApiException(
            'Ошибка сервера (${response.statusCode}), попробуйте позже',
          );
        }
        throw ApiException('Ошибка ${response.statusCode}');
    }

    try {
      Object? data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) return data;
    } on FormatException {
      // ниже
    }
    throw ApiException('Сервер прислал некорректный ответ');
  }
}
