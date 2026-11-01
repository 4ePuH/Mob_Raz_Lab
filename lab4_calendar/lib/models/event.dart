import 'package:flutter/material.dart';

// Категории событий (доп. задание - цвета категорий)
enum EventCategory {
  work('Работа', Colors.blue),
  study('Учёба', Colors.green),
  personal('Личное', Colors.orange),
  other('Другое', Colors.grey);

  final String label;
  final Color color;

  const EventCategory(this.label, this.color);
}

class Event {
  final String id;
  final String title;
  final String description;
  // дата и время начала
  final DateTime start;
  // окончание необязательное, если есть - в тот же день и позже начала
  final DateTime? end;
  final EventCategory category;

  const Event({
    required this.id,
    required this.title,
    this.description = '',
    required this.start,
    this.end,
    this.category = EventCategory.other,
  });

  Event copyWith({
    String? title,
    String? description,
    DateTime? start,
    DateTime? end,
    bool clearEnd = false,
    EventCategory? category,
  }) {
    return Event(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      start: start ?? this.start,
      // через null тут не сбросить конец, поэтому отдельный флаг clearEnd
      end: clearEnd ? null : (end ?? this.end),
      category: category ?? this.category,
    );
  }

  bool isOnDay(DateTime day) => isSameDate(start, day);
}

// сравниваем только год, месяц и день, время и часовой пояс не важны.
// table_calendar отдаёт дни в UTC, а события у нас в локальном времени,
// поэтому обычный == тут не подходит
bool isSameDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// убираем время и UTC: 2026-11-02 00:00 по местному времени
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// проверка времени начала и окончания, null - всё в порядке
String? checkEventTime(DateTime start, DateTime? end) {
  if (end == null) return null;
  if (!isSameDate(start, end)) {
    return 'Событие должно закончиться в тот же день';
  }
  if (!end.isAfter(start)) {
    return 'Окончание должно быть позже начала';
  }
  return null;
}
