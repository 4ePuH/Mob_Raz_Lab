import 'package:intl/intl.dart';

import '../models/event.dart';

String formatTime(DateTime d) => DateFormat.Hm('ru').format(d);

// "10:00 – 11:30" или просто "10:00", если конца нет
String formatEventTime(Event e) {
  if (e.end == null) return formatTime(e.start);
  return '${formatTime(e.start)} – ${formatTime(e.end!)}';
}

// "понедельник, 2 ноября"
String formatDayTitle(DateTime d) => DateFormat('EEEE, d MMMM', 'ru').format(d);

// "2 нояб. 2026 г." в форме выбора даты
String formatDate(DateTime d) => DateFormat.yMMMd('ru').format(d);

// yMMMM даёт "ноябрь 2026 г.", поэтому формат свой:
// LLLL - месяц в именительном падеже, и делаем первую букву заглавной
String formatMonthTitle(DateTime d) {
  String s = DateFormat('LLLL y', 'ru').format(d);
  return s[0].toUpperCase() + s.substring(1);
}
