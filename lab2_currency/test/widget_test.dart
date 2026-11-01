import 'dart:convert';

import 'package:currency_converter/data/cbr_api_client.dart';
import 'package:currency_converter/data/currency_repository.dart';
import 'package:currency_converter/data/favorites_storage.dart';
import 'package:currency_converter/main.dart';
import 'package:currency_converter/state/converter_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sample_response.dart';

ConverterApp makeApp({bool fail = false}) {
  MockClient client = MockClient((_) async {
    if (fail) throw http.ClientException('no net');
    return http.Response.bytes(utf8.encode(sampleResponse), 200);
  });
  ConverterState state = ConverterState(
    repository: CurrencyRepository(CbrApiClient(client: client)),
    favoritesStorage: FavoritesStorage(),
  );
  return ConverterApp(state: state);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('конвертация 100 EUR в рубли', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '100');
    await tester.tap(find.text('Конвертировать'));
    await tester.pumpAndSettle();

    expect(find.text('10 000.00 RUB'), findsOneWidget);
    expect(find.text('Курс ЦБ РФ на 31.10.2026'), findsOneWidget);
  });

  testWidgets('пустая сумма - подсказка под полем', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Конвертировать'));
    await tester.pump();

    expect(find.text('Введите сумму'), findsOneWidget);
  });

  testWidgets('без интернета - ошибка и кнопка повтора', (tester) async {
    await tester.pumpWidget(makeApp(fail: true));
    await tester.pumpAndSettle();

    expect(find.text('Нет подключения к интернету'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('выбор валюты из списка и звёздочка', (tester) async {
    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();

    // кнопка "В" с рублём
    await tester.tap(find.text('RUB').first);
    await tester.pumpAndSettle();
    expect(find.text('Избранные'), findsOneWidget);

    // отмечаем драм и выбираем его
    await tester.tap(find.byTooltip('В избранное').first);
    await tester.pump();
    await tester.tap(find.text('Армянских драмов'));
    await tester.pumpAndSettle();

    expect(find.text('AMD'), findsOneWidget);
  });

  testWidgets('влезает на маленький экран', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(makeApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456789');
    await tester.tap(find.text('Конвертировать'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
