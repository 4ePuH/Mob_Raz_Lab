import 'package:intl/intl.dart';

// 4.6 -> "5°", -0.3 -> "0°" (а не "-0°")
String formatTemp(double t) {
  int rounded = t.round();
  if (rounded == 0) return '0°';
  return '$rounded°';
}

// 1 день, 3 дня, 7 дней, 11 дней, 21 день
String daysWord(int n) {
  int lastTwo = n % 100;
  int last = n % 10;
  if (lastTwo >= 11 && lastTwo <= 14) return 'дней';
  if (last == 1) return 'день';
  if (last >= 2 && last <= 4) return 'дня';
  return 'дней';
}

// "пн, 2 нояб." -> "Пн, 2 нояб."
String formatDay(DateTime d) {
  String s = DateFormat('EE, d MMM', 'ru').format(d);
  return s[0].toUpperCase() + s.substring(1);
}

// "01.11 в 17:05"
String formatLoadedAt(DateTime d) {
  return DateFormat("dd.MM 'в' HH:mm", 'ru').format(d);
}
