import 'dart:convert';

import 'package:currency_converter/data/cbr_api_client.dart';
import 'package:currency_converter/data/currency_repository.dart';
import 'package:currency_converter/data/favorites_storage.dart';
import 'package:currency_converter/state/converter_state.dart';
import 'package:currency_converter/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sample_response.dart';

ConverterState makeState({int statusCode = 200}) {
  MockClient client = MockClient((_) async {
    if (statusCode != 200) return http.Response('error', statusCode);
    return http.Response.bytes(utf8.encode(sampleResponse), 200);
  });
  return ConverterState(
    repository: CurrencyRepository(CbrApiClient(client: client)),
    favoritesStorage: FavoritesStorage(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('после загрузки статус success', () async {
    ConverterState state = makeState();
    await state.init();
    expect(state.status, LoadStatus.success);
    expect(state.rates, isNotNull);
  });

  test('ошибка сервера -> статус error и сообщение', () async {
    ConverterState state = makeState(statusCode: 503);
    await state.init();
    expect(state.status, LoadStatus.error);
    expect(state.loadError, contains('503'));
  });

  test('100 EUR -> RUB', () async {
    ConverterState state = makeState();
    await state.init();
    state.setAmount('100');
    state.convert();
    expect(state.inputError, isNull);
    expect(state.result, closeTo(10000, 1e-9));
  });

  test('пустая сумма', () async {
    ConverterState state = makeState();
    await state.init();
    state.setAmount('   ');
    state.convert();
    expect(state.result, isNull);
    expect(state.inputError, 'Введите сумму');
  });

  test('отрицательная сумма', () async {
    ConverterState state = makeState();
    await state.init();
    state.setAmount('-5');
    state.convert();
    expect(state.result, isNull);
    expect(state.inputError, 'Сумма не может быть отрицательной');
  });

  test('мусор вместо числа', () async {
    ConverterState state = makeState();
    await state.init();
    for (String bad in ['1.2.3', '--1', '.', 'NaN']) {
      state.setAmount(bad);
      state.convert();
      expect(state.result, isNull, reason: bad);
      expect(state.inputError, 'Сумма должна быть числом', reason: bad);
    }
  });

  test('запятая и пробелы в сумме', () async {
    ConverterState state = makeState();
    await state.init();
    state.setAmount('1 000,5');
    state.convert();
    expect(state.result, closeTo(100050, 1e-6));
  });

  test('смена валют местами меняет направление', () async {
    ConverterState state = makeState();
    await state.init();
    state.setAmount('100');
    state.convert();
    expect(state.result, closeTo(10000, 1e-9));

    state.swap();
    expect(state.fromCode, 'RUB');
    expect(state.toCode, 'EUR');
    // результат пересчитался сам: 100 руб = 1 евро
    expect(state.result, closeTo(1, 1e-9));
  });

  test('новая сумма сбрасывает старый результат', () async {
    ConverterState state = makeState();
    await state.init();
    state.setAmount('100');
    state.convert();
    state.setAmount('200');
    expect(state.result, isNull);
  });

  group('избранное', () {
    test('по умолчанию есть USD и EUR', () async {
      ConverterState state = makeState();
      await state.init();
      expect(state.isFavorite('USD'), isTrue);
      expect(state.isFavorite('AMD'), isFalse);
    });

    test('добавить и убрать, сохраняется между запусками', () async {
      ConverterState state = makeState();
      await state.init();
      await state.toggleFavorite('AMD');
      await state.toggleFavorite('USD');

      // "перезапуск" - новое состояние с тем же хранилищем
      ConverterState again = makeState();
      await again.init();
      expect(again.isFavorite('AMD'), isTrue);
      expect(again.isFavorite('USD'), isFalse);
    });

    test('избранные идут отдельным списком', () async {
      ConverterState state = makeState();
      await state.init();
      List<String> fav = state.favoriteCurrencies.map((c) => c.code).toList();
      List<String> other = state.otherCurrencies.map((c) => c.code).toList();
      // CNY в избранном по умолчанию, но в тестовом ответе его нет
      expect(fav, unorderedEquals(['USD', 'EUR']));
      expect(other, unorderedEquals(['RUB', 'AMD']));
    });
  });

  group('форматирование', () {
    test('разделение тысяч', () {
      expect(formatMoney(1234567.891), '1 234 567.89');
      expect(formatMoney(100), '100.00');
      expect(formatMoney(0.2), '0.2000');
      expect(formatMoney(0), '0.00');
    });

    test('дата', () {
      expect(formatDate(DateTime(2026, 3, 5)), '05.03.2026');
    });
  });
}
