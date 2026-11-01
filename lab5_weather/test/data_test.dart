import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/data/weather_api_client.dart';
import 'package:weather_app/data/weather_cache.dart';
import 'package:weather_app/data/weather_repository.dart';
import 'package:weather_app/models/city.dart';
import 'package:weather_app/models/weather.dart';
import 'package:weather_app/models/weather_code.dart';
import 'package:weather_app/utils/format.dart';

import 'fake_server.dart';

WeatherApiClient apiWith(int status, [String body = '{}']) {
  return WeatherApiClient(
    client: MockClient((_) async => jsonResponse(body, status)),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('модели', () {
    test('город из ответа геокодера', () {
      Map<String, dynamic> json = jsonDecode(moscowSearch);
      City city = City.fromJson(json['results'][0]);
      expect(city.name, 'Москва');
      expect(city.title, 'Москва, Россия');
      expect(city.latitude, closeTo(55.75, 0.01));
    });

    test('погода из ответа прогноза', () {
      City city = const City(name: 'Москва', country: 'Россия', latitude: 0, longitude: 0);
      Weather w = Weather.fromJson(
        jsonDecode(moscowForecast),
        city,
        loadedAt: DateTime(2026, 11, 1, 17, 5),
      );
      expect(w.current.temperature, 4.5);
      expect(w.current.humidity, 83);
      expect(w.current.windSpeed, 1.6);
      // 1010.6 гПа = 758 мм рт. ст.
      expect(w.current.pressureMmHg, 758);
      expect(w.daily.length, 3);
      expect(w.daily[1].date, DateTime(2026, 11, 2));
      expect(w.daily[1].maxTemp, 0.8);
      expect(w.daily[1].minTemp, -1.3);
    });

    test('коды погоды', () {
      expect(weatherDescription(0), 'Ясно');
      expect(weatherDescription(71), 'Небольшой снег');
      expect(weatherDescription(95), 'Гроза');
      expect(weatherDescription(12345), 'Неизвестно');
    });

    test('форматирование', () {
      expect(formatTemp(4.5), '5°');
      expect(formatTemp(-1.3), '-1°');
      expect(formatTemp(-0.3), '0°');
      expect(formatDay(DateTime(2026, 11, 2)), startsWith('Пн, 2'));
      expect(formatLoadedAt(DateTime(2026, 11, 1, 17, 5)), '01.11 в 17:05');
      expect(daysWord(1), 'день');
      expect(daysWord(3), 'дня');
      expect(daysWord(7), 'дней');
      expect(daysWord(11), 'дней');
      expect(daysWord(21), 'день');
    });
  });

  group('api клиент', () {
    test('город не найден - пустой список', () async {
      expect(await apiWith(200, emptySearch).searchCity('qwzzxq'), isEmpty);
    });

    test('404', () async {
      expect(
        apiWith(404).fetchForecast(0, 0),
        throwsA(isA<ApiException>().having((e) => e.message, 'm', contains('404'))),
      );
    });

    test('500', () async {
      expect(
        apiWith(500).fetchForecast(0, 0),
        throwsA(isA<ApiException>()
            .having((e) => e.message, 'm', contains('Ошибка сервера'))
            .having((e) => e.noConnection, 'noConnection', isFalse)),
      );
    });

    test('400', () async {
      expect(
        apiWith(400, '{"error":true}').fetchForecast(999, 0),
        throwsA(isA<ApiException>()),
      );
    });

    test('нет интернета', () async {
      WeatherApiClient api = WeatherApiClient(
        client: MockClient((_) async => throw http.ClientException('no')),
      );
      expect(
        api.searchCity('Москва'),
        throwsA(isA<ApiException>().having((e) => e.noConnection, 'noConnection', isTrue)),
      );
    });

    test('вместо json что-то другое', () async {
      expect(apiWith(200, '<html></html>').fetchForecast(0, 0), throwsA(isA<ApiException>()));
    });
  });

  group('репозиторий и кэш', () {
    late FakeServer server;
    late WeatherRepository repo;

    setUp(() {
      server = FakeServer();
      repo = WeatherRepository(
        api: WeatherApiClient(client: server.client),
        cache: WeatherCache(),
        now: () => DateTime(2026, 11, 1, 17, 5),
      );
    });

    test('корректный город', () async {
      Weather w = await repo.getWeather('  Москва ');
      expect(w.city.name, 'Москва');
      expect(w.fromCache, isFalse);
      expect(await repo.lastCity(), 'Москва');
    });

    test('несуществующий город', () async {
      expect(repo.getWeather('Абырвалг'), throwsA(isA<CityNotFoundException>()));
    });

    test('без интернета и без кэша - ошибка', () async {
      server.online = false;
      expect(repo.getWeather('Москва'), throwsA(isA<ApiException>()));
    });

    test('без интернета, но город уже загружали - берём из кэша', () async {
      await repo.getWeather('Москва');
      server.online = false;

      Weather w = await repo.getWeather('москва');
      expect(w.fromCache, isTrue);
      expect(w.city.name, 'Москва');
      expect(w.loadedAt, DateTime(2026, 11, 1, 17, 5));
      expect(w.current.temperature, 4.5);
    });

    test('кэш находится и по тому, что вводил пользователь', () async {
      await repo.getWeather('Moscow');
      server.online = false;
      Weather w = await repo.getWeather('moscow');
      expect(w.city.name, 'Москва');
    });

    test('при ошибке сервера кэш не подставляется', () async {
      await repo.getWeather('Москва');
      server.forecastStatus = 500;
      // сервер доступен, но сломан - честно показываем ошибку
      expect(repo.getWeather('Москва'), throwsA(isA<ApiException>()));
    });
  });
}
