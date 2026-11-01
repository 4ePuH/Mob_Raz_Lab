// 1234567.891 -> "1 234 567.89"
// для маленьких сумм оставляем больше знаков, иначе получится 0.00
String formatMoney(double value) {
  int digits = 2;
  if (value != 0 && value.abs() < 1) {
    digits = 4;
  }
  if (value != 0 && value.abs() < 0.0001) {
    digits = 8;
  }

  String fixed = value.toStringAsFixed(digits);
  List<String> parts = fixed.split('.');
  String intPart = parts[0];
  String fraction = parts.length > 1 ? parts[1] : '';

  String sign = '';
  if (intPart.startsWith('-')) {
    sign = '-';
    intPart = intPart.substring(1);
  }

  // вставляем пробел через каждые 3 цифры с конца
  StringBuffer buf = StringBuffer();
  for (int i = 0; i < intPart.length; i++) {
    if (i > 0 && (intPart.length - i) % 3 == 0) {
      buf.write(' ');
    }
    buf.write(intPart[i]);
  }

  return fraction.isEmpty ? '$sign$buf' : '$sign$buf.$fraction';
}

String formatDate(DateTime d) {
  String day = d.day.toString().padLeft(2, '0');
  String month = d.month.toString().padLeft(2, '0');
  return '$day.$month.${d.year}';
}
