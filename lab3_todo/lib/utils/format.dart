String _two(int n) => n.toString().padLeft(2, '0');

// 01.11.2026, 14:05
String formatDateTime(DateTime d) {
  return '${_two(d.day)}.${_two(d.month)}.${d.year}, ${_two(d.hour)}:${_two(d.minute)}';
}
