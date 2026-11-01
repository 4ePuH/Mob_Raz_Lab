import 'package:flutter/foundation.dart';

import '../data/cbr_api_client.dart';
import '../data/currency_repository.dart';
import '../data/favorites_storage.dart';
import '../models/currency.dart';

enum LoadStatus { loading, success, error }

// Всё состояние экрана конвертера.
// Экран подписан на него через ListenableBuilder и перерисовывается после notifyListeners()
class ConverterState extends ChangeNotifier {
  final CurrencyRepository repository;
  final FavoritesStorage favoritesStorage;

  ConverterState({required this.repository, required this.favoritesStorage});

  LoadStatus status = LoadStatus.loading;
  String? loadError;
  RatesData? rates;

  String fromCode = 'EUR';
  String toCode = 'RUB';
  String amountText = '';
  String? inputError;

  // результат последней конвертации, null - ещё не считали
  double? result;
  double? resultAmount;

  List<String> favorites = [];

  static const double maxAmount = 1e12;

  Currency? get from => rates?.find(fromCode);
  Currency? get to => rates?.find(toCode);

  // курс 1 единицы from в валюте to
  double? get rate {
    if (from == null || to == null) return null;
    return convertAmount(1, from!, to!);
  }

  Future<void> init() async {
    favorites = await favoritesStorage.load();
    await loadRates();
  }

  Future<void> loadRates() async {
    status = LoadStatus.loading;
    loadError = null;
    notifyListeners();

    try {
      rates = await repository.loadRates();
      status = LoadStatus.success;
      // если результат уже был на экране, пересчитаем по свежему курсу
      if (result != null) {
        _calculate();
      }
    } on ApiException catch (e) {
      status = LoadStatus.error;
      loadError = e.message;
    }
    notifyListeners();
  }

  void setAmount(String text) {
    amountText = text;
    // старый результат относится к старой сумме, убираем
    inputError = null;
    result = null;
    notifyListeners();
  }

  void setFrom(String code) {
    fromCode = code;
    _recalculateIfShown();
  }

  void setTo(String code) {
    toCode = code;
    _recalculateIfShown();
  }

  void swap() {
    String tmp = fromCode;
    fromCode = toCode;
    toCode = tmp;
    _recalculateIfShown();
  }

  void convert() {
    _calculate();
    notifyListeners();
  }

  void _recalculateIfShown() {
    if (result != null) {
      _calculate();
    }
    notifyListeners();
  }

  void _calculate() {
    result = null;
    if (from == null || to == null) return;

    // разрешаем писать и через запятую, и с пробелами: "1 000,5"
    String text = amountText.trim().replaceAll(' ', '').replaceAll(',', '.');
    if (text.isEmpty) {
      inputError = 'Введите сумму';
      return;
    }

    double? amount = double.tryParse(text);
    // tryParse понимает и "NaN", и "Infinity", такое тоже не пускаем
    if (amount == null || amount.isNaN || amount.isInfinite) {
      inputError = 'Сумма должна быть числом';
      return;
    }
    if (amount < 0) {
      inputError = 'Сумма не может быть отрицательной';
      return;
    }
    if (amount > maxAmount) {
      inputError = 'Слишком большая сумма';
      return;
    }

    inputError = null;
    resultAmount = amount;
    result = convertAmount(amount, from!, to!);
  }

  // --- избранное ---

  bool isFavorite(String code) => favorites.contains(code);

  Future<void> toggleFavorite(String code) async {
    if (favorites.contains(code)) {
      favorites.remove(code);
    } else {
      favorites.add(code);
    }
    notifyListeners();
    await favoritesStorage.save(favorites);
  }

  // список для выбора: сначала избранные, потом остальные
  List<Currency> get favoriteCurrencies {
    if (rates == null) return [];
    return rates!.currencies.where((c) => favorites.contains(c.code)).toList();
  }

  List<Currency> get otherCurrencies {
    if (rates == null) return [];
    return rates!.currencies.where((c) => !favorites.contains(c.code)).toList();
  }
}
