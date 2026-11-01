// Валюта из ответа ЦБ.
// ЦБ отдаёт курс не всегда за 1 единицу, а за Nominal единиц
// (например 100 армянских драмов = 22.5 руб), поэтому Value делим на Nominal
class Currency {
  final String code;
  final String name;
  final int nominal;
  final double value;

  const Currency({
    required this.code,
    required this.name,
    required this.nominal,
    required this.value,
  });

  // рубля в ответе ЦБ нет, он базовая валюта, добавляем сами
  static const Currency rub = Currency(
    code: 'RUB',
    name: 'Российский рубль',
    nominal: 1,
    value: 1,
  );

  // сколько рублей стоит 1 единица валюты
  double get rubPerUnit => value / nominal;

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['CharCode'] as String,
      name: json['Name'] as String,
      nominal: (json['Nominal'] as num).toInt(),
      value: (json['Value'] as num).toDouble(),
    );
  }
}

// Все курсы на одну дату
class RatesData {
  final DateTime date;
  final List<Currency> currencies;

  RatesData({required this.date, required this.currencies});

  factory RatesData.fromJson(Map<String, dynamic> json) {
    Object? valute = json['Valute'];
    Object? date = json['Date'];
    if (valute is! Map<String, dynamic> || date is! String) {
      throw const FormatException('нет полей Valute или Date');
    }

    List<Currency> list = [Currency.rub];
    for (Object? item in valute.values) {
      list.add(Currency.fromJson(item as Map<String, dynamic>));
    }

    // дата приходит как "2026-10-31T11:30:00+03:00".
    // берём только сам день, иначе при переводе в UTC день может съехать
    return RatesData(
      date: DateTime.parse(date.substring(0, 10)),
      currencies: list,
    );
  }

  Currency? find(String code) {
    for (Currency c in currencies) {
      if (c.code == code) return c;
    }
    return null;
  }
}

// перевод идёт через рубли: сумма -> рубли -> нужная валюта
double convertAmount(double amount, Currency from, Currency to) {
  return amount * from.rubPerUnit / to.rubPerUnit;
}
