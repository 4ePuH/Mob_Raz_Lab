import '../models/currency.dart';
import 'cbr_api_client.dart';

// Репозиторий отдаёт приложению уже готовые модели.
// Экран и состояние не знают, откуда курсы: из сети, файла или ещё откуда-то
class CurrencyRepository {
  final CbrApiClient api;

  CurrencyRepository(this.api);

  Future<RatesData> loadRates() async {
    Map<String, dynamic> json = await api.fetchDaily();
    try {
      return RatesData.fromJson(json);
    } catch (e) {
      // FormatException или TypeError, если какое-то поле не того типа
      throw ApiException('Не удалось разобрать курсы валют');
    }
  }
}
