import 'package:flutter/foundation.dart';

import '../data/weather_api_client.dart';
import '../data/weather_repository.dart';
import '../models/weather.dart';

// initial - ещё ничего не искали, notFound - пустой результат поиска
enum WeatherStatus { initial, loading, success, notFound, error }

class WeatherState extends ChangeNotifier {
  final WeatherRepository repository;

  WeatherState(this.repository);

  WeatherStatus status = WeatherStatus.initial;
  Weather? weather;
  String? errorMessage;
  // ошибка под полем ввода (пустой запрос)
  String? inputError;
  String lastQuery = '';

  // номер последнего запроса. Если пользователь успел искать два города подряд,
  // ответ на первый запрос может прийти позже второго - такой ответ выбрасываем
  int _requestId = 0;

  // при запуске сразу показываем последний город, который смотрели
  Future<void> init() async {
    String? last = await repository.lastCity();
    if (last != null) {
      await search(last);
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      inputError = 'Введите название города';
      notifyListeners();
      return;
    }

    inputError = null;
    errorMessage = null;
    lastQuery = query.trim();
    status = WeatherStatus.loading;
    notifyListeners();

    _requestId++;
    int myId = _requestId;
    try {
      Weather result = await repository.getWeather(lastQuery);
      if (myId != _requestId) return;
      weather = result;
      status = WeatherStatus.success;
    } on CityNotFoundException {
      if (myId != _requestId) return;
      weather = null;
      status = WeatherStatus.notFound;
    } on ApiException catch (e) {
      if (myId != _requestId) return;
      weather = null;
      errorMessage = e.message;
      status = WeatherStatus.error;
    }
    notifyListeners();
  }

  Future<void> retry() => search(lastQuery);
}
