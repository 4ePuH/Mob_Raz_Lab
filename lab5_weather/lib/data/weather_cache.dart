import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/city.dart';
import '../models/weather.dart';

// Кэш (доп. задание). Храним последний удачный ответ сервера для каждого города,
// чтобы без интернета показать хотя бы его
class WeatherCache {
  static const String _lastCityKey = 'last_city';

  // "Москва", " москва " и "МОСКВА" - один и тот же ключ
  static String _key(String name) => 'weather_${name.trim().toLowerCase()}';

  Future<void> save({
    required String query,
    required City city,
    required Map<String, dynamic> forecastJson,
    required DateTime loadedAt,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String raw = jsonEncode({
      'city': city.toJson(),
      'forecast': forecastJson,
      'loadedAt': loadedAt.toIso8601String(),
    });
    // пишем и под названием из ответа, и под тем, что ввёл пользователь
    // (ввести могли "moscow", а сервер вернул "Москва")
    await prefs.setString(_key(city.name), raw);
    if (_key(query) != _key(city.name)) {
      await prefs.setString(_key(query), raw);
    }
    await prefs.setString(_lastCityKey, city.name);
  }

  Future<Weather?> load(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(_key(name));
    if (raw == null) return null;

    try {
      Map<String, dynamic> data = jsonDecode(raw) as Map<String, dynamic>;
      return Weather.fromJson(
        data['forecast'] as Map<String, dynamic>,
        City.fromJson(data['city'] as Map<String, dynamic>),
        loadedAt: DateTime.parse(data['loadedAt'] as String),
        fromCache: true,
      );
    } catch (e) {
      // испорченный кэш просто игнорируем
      return null;
    }
  }

  Future<String?> lastCity() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastCityKey);
  }
}
