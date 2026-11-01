// Урезанный ответ cbr-xml-daily.ru, чтобы тесты не ходили в интернет.
// EUR взял круглый, чтобы было удобно проверять: 100 EUR = 10000 RUB
const String sampleResponse = '''
{
  "Date": "2026-10-31T11:30:00+03:00",
  "PreviousDate": "2026-10-30T11:30:00+03:00",
  "Timestamp": "2026-10-31T20:00:00+03:00",
  "Valute": {
    "USD": {"ID": "R01235", "NumCode": "840", "CharCode": "USD", "Nominal": 1, "Name": "Доллар США", "Value": 80.0, "Previous": 79.5},
    "EUR": {"ID": "R01239", "NumCode": "978", "CharCode": "EUR", "Nominal": 1, "Name": "Евро", "Value": 100.0, "Previous": 99.1},
    "AMD": {"ID": "R01060", "NumCode": "051", "CharCode": "AMD", "Nominal": 100, "Name": "Армянских драмов", "Value": 20.0, "Previous": 20.1}
  }
}
''';
