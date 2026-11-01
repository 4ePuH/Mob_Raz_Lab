import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

// Ответы, похожие на настоящие ответы Open-Meteo (взял реальные и сократил)
const String moscowSearch = '''
{"results":[{"id":524901,"name":"Москва","latitude":55.75204,"longitude":37.61781,
"country_code":"RU","timezone":"Europe/Moscow","country":"Россия","admin1":"Москва"}]}
''';

const String emptySearch = '{"generationtime_ms":0.14}';

const String moscowForecast = '''
{"latitude":55.78,"longitude":37.57,"timezone":"Europe/Moscow",
"current":{"time":"2026-11-01T17:00","interval":900,"temperature_2m":4.5,
"relative_humidity_2m":83,"apparent_temperature":1.8,"weather_code":0,
"wind_speed_10m":1.6,"surface_pressure":1010.6},
"daily":{"time":["2026-11-01","2026-11-02","2026-11-03"],
"weather_code":[45,71,3],
"temperature_2m_max":[8.7,0.8,0.3],
"temperature_2m_min":[0.1,-1.3,-1.5]}}
''';

http.Response jsonResponse(String body, [int code = 200]) {
  return http.Response.bytes(utf8.encode(body), code);
}

// Поддельный сервер: online=false - "нет интернета"
class FakeServer {
  bool online = true;
  int forecastStatus = 200;
  int requests = 0;

  MockClient get client => MockClient((request) async {
        requests++;
        if (!online) throw http.ClientException('no internet');

        if (request.url.host.startsWith('geocoding')) {
          String name = request.url.queryParameters['name'] ?? '';
          if (name.toLowerCase() == 'москва' || name.toLowerCase() == 'moscow') {
            return jsonResponse(moscowSearch);
          }
          return jsonResponse(emptySearch);
        }

        if (forecastStatus != 200) {
          return jsonResponse('{"error":true,"reason":"oops"}', forecastStatus);
        }
        return jsonResponse(moscowForecast);
      });
}
