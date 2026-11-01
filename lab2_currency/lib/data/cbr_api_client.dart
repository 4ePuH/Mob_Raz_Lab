import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

// Запрос к API с курсами ЦБ РФ (https://www.cbr-xml-daily.ru), ключ не нужен.
// Тут только сеть и разбор JSON в Map, про модели этот класс не знает
class CbrApiClient {
  static const String url = 'https://www.cbr-xml-daily.ru/daily_json.js';
  static const Duration timeout = Duration(seconds: 10);

  final http.Client client;

  // client можно подменить в тестах на MockClient
  CbrApiClient({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> fetchDaily() async {
    http.Response response;
    try {
      response = await client.get(Uri.parse(url)).timeout(timeout);
    } on TimeoutException {
      throw ApiException('Сервер долго не отвечает, попробуйте ещё раз');
    } catch (e) {
      // без интернета http кидает ClientException (на телефоне SocketException)
      throw ApiException('Нет подключения к интернету');
    }

    if (response.statusCode != 200) {
      throw ApiException('Ошибка сервера (код ${response.statusCode})');
    }

    try {
      Object? data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) {
        return data;
      }
    } on FormatException {
      // ниже выкинем общую ошибку
    }
    throw ApiException('Сервер прислал некорректный ответ');
  }
}
