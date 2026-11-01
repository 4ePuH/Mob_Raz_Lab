import 'dart:convert';

import 'package:currency_converter/data/cbr_api_client.dart';
import 'package:currency_converter/data/currency_repository.dart';
import 'package:currency_converter/models/currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'sample_response.dart';

http.Response okResponse(String body) {
  // кириллица в названиях, поэтому отдаём байты в utf8
  return http.Response.bytes(utf8.encode(body), 200);
}

void main() {
  group('модели', () {
    test('разбор ответа ЦБ', () {
      RatesData data = RatesData.fromJson(jsonDecode(sampleResponse));
      expect(data.date, DateTime(2026, 10, 31));
      // 3 валюты из ответа + рубль
      expect(data.currencies.length, 4);
      expect(data.find('RUB'), isNotNull);
      expect(data.find('EUR')!.name, 'Евро');
      expect(data.find('XXX'), isNull);
    });

    test('номинал 100 учитывается', () {
      RatesData data = RatesData.fromJson(jsonDecode(sampleResponse));
      // 100 драмов = 20 руб -> 1 драм = 0.2 руб
      expect(data.find('AMD')!.rubPerUnit, closeTo(0.2, 1e-9));
    });

    test('100 EUR -> RUB', () {
      RatesData data = RatesData.fromJson(jsonDecode(sampleResponse));
      double r = convertAmount(100, data.find('EUR')!, data.find('RUB')!);
      expect(r, closeTo(10000, 1e-9));
    });

    test('кросс-курс через рубль', () {
      RatesData data = RatesData.fromJson(jsonDecode(sampleResponse));
      // 1 EUR = 100 руб, 1 USD = 80 руб -> 1 EUR = 1.25 USD
      double r = convertAmount(1, data.find('EUR')!, data.find('USD')!);
      expect(r, closeTo(1.25, 1e-9));
    });

    test('без Valute - ошибка формата', () {
      expect(
        () => RatesData.fromJson({'Date': '2026-10-31'}),
        throwsFormatException,
      );
    });
  });

  group('api клиент', () {
    test('успешный ответ', () async {
      CbrApiClient api = CbrApiClient(
        client: MockClient((_) async => okResponse(sampleResponse)),
      );
      Map<String, dynamic> json = await api.fetchDaily();
      expect(json['Valute'], isA<Map>());
    });

    test('ошибка сервера 500', () async {
      CbrApiClient api = CbrApiClient(
        client: MockClient((_) async => http.Response('oops', 500)),
      );
      expect(
        api.fetchDaily(),
        throwsA(
          isA<ApiException>().having((e) => e.message, 'message', contains('500')),
        ),
      );
    });

    test('нет интернета', () async {
      CbrApiClient api = CbrApiClient(
        client: MockClient((_) async => throw http.ClientException('no net')),
      );
      expect(
        api.fetchDaily(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Нет подключения к интернету',
          ),
        ),
      );
    });

    test('вместо json пришёл html', () async {
      CbrApiClient api = CbrApiClient(
        client: MockClient((_) async => okResponse('<html>error</html>')),
      );
      expect(api.fetchDaily(), throwsA(isA<ApiException>()));
    });
  });

  group('репозиторий', () {
    test('json правильный, но поля не того типа', () async {
      CbrApiClient api = CbrApiClient(
        client: MockClient(
          (_) async => okResponse('{"Date": "2026-10-31", "Valute": {"USD": 5}}'),
        ),
      );
      CurrencyRepository repo = CurrencyRepository(api);
      expect(repo.loadRates(), throwsA(isA<ApiException>()));
    });
  });
}
