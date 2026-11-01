import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/data/weather_api_client.dart';
import 'package:weather_app/data/weather_cache.dart';
import 'package:weather_app/data/weather_repository.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/state/weather_state.dart';

import 'fake_server.dart';

Future<WeatherState> openApp(WidgetTester tester, FakeServer server) async {
  WeatherState state = WeatherState(WeatherRepository(
    api: WeatherApiClient(client: server.client),
    cache: WeatherCache(),
    now: () => DateTime(2026, 11, 1, 17, 5),
  ));
  // сначала пустой экран, иначе при повторном вызове Flutter переиспользует
  // старый State и initState (загрузка последнего города) не вызовется
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(WeatherApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

Future<void> searchCity(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField), name);
  await tester.tap(find.byTooltip('Найти'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('стартовый экран', (tester) async {
    await openApp(tester, FakeServer());
    expect(find.text('Введите город, чтобы узнать погоду'), findsOneWidget);
  });

  testWidgets('успешная загрузка', (tester) async {
    await openApp(tester, FakeServer());
    await searchCity(tester, 'Москва');

    expect(find.text('Москва, Россия'), findsOneWidget);
    expect(find.text('5°'), findsOneWidget);
    expect(find.text('Ясно'), findsOneWidget);
    expect(find.text('83%'), findsOneWidget);
    expect(find.text('1.6 м/с'), findsOneWidget);
    expect(find.text('758 мм рт. ст.'), findsOneWidget);
    expect(find.text('Прогноз на 3 дня'), findsOneWidget);
  });

  testWidgets('пустой запрос', (tester) async {
    FakeServer server = FakeServer();
    await openApp(tester, server);
    await searchCity(tester, '   ');
    expect(find.text('Введите название города'), findsOneWidget);
    // в сеть даже не ходили
    expect(server.requests, 0);
  });

  testWidgets('несуществующий город', (tester) async {
    await openApp(tester, FakeServer());
    await searchCity(tester, 'Абырвалг');
    expect(find.textContaining('не найден'), findsOneWidget);
  });

  testWidgets('нет интернета - ошибка и повтор', (tester) async {
    FakeServer server = FakeServer()..online = false;
    await openApp(tester, server);
    await searchCity(tester, 'Москва');
    expect(find.text('Нет подключения к интернету'), findsOneWidget);

    // интернет появился, жмём "Повторить"
    server.online = true;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Москва, Россия'), findsOneWidget);
  });

  testWidgets('ошибка сервера', (tester) async {
    FakeServer server = FakeServer()..forecastStatus = 503;
    await openApp(tester, server);
    await searchCity(tester, 'Москва');
    expect(find.textContaining('Ошибка сервера (503)'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('без сети показываем кэш с пометкой', (tester) async {
    FakeServer server = FakeServer();
    await openApp(tester, server);
    await searchCity(tester, 'Москва');

    server.online = false;
    await searchCity(tester, 'Москва');
    expect(find.text('Нет связи с сервером'), findsOneWidget);
    expect(find.textContaining('01.11 в 17:05'), findsOneWidget);
    expect(find.text('Москва, Россия'), findsOneWidget);
  });

  testWidgets('при запуске открывается последний город', (tester) async {
    FakeServer server = FakeServer();
    await openApp(tester, server);
    await searchCity(tester, 'Москва');

    // "перезапуск" приложения
    await openApp(tester, server);
    expect(find.text('Москва, Россия'), findsOneWidget);
  });

  testWidgets('прогноз по дням', (tester) async {
    await openApp(tester, FakeServer());
    await searchCity(tester, 'Москва');
    // прокручиваемых областей на экране несколько (поле ввода тоже), указываем список
    await tester.scrollUntilVisible(
      find.text('Сегодня'),
      200,
      scrollable: find.descendant(
        of: find.byType(ListView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('Сегодня'), findsOneWidget);
    expect(find.text('9° / 0°'), findsOneWidget);
    expect(find.text('Небольшой снег'), findsOneWidget);
  });

  testWidgets('влезает на маленький экран', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openApp(tester, FakeServer());
    await searchCity(tester, 'Москва');
    expect(tester.takeException(), isNull);
  });
}
