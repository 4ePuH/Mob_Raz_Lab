import 'package:flutter/foundation.dart';

import '../data/event_repository.dart';
import '../models/event.dart';

// Состояние экрана: какой месяц открыт, какой день выбран, и работа с событиями
class CalendarState extends ChangeNotifier {
  final EventRepository repository;

  // день, месяц которого сейчас показан в календаре
  DateTime focusedDay;
  DateTime selectedDay;

  // initialDay нужен в тестах, чтобы не зависеть от сегодняшней даты
  CalendarState(this.repository, {DateTime? initialDay})
      : focusedDay = dateOnly(initialDay ?? DateTime.now()),
        selectedDay = dateOnly(initialDay ?? DateTime.now());

  List<Event> eventsForDay(DateTime day) => repository.getForDay(day);

  List<Event> get selectedEvents => repository.getForDay(selectedDay);

  void selectDay(DateTime day) {
    selectedDay = dateOnly(day);
    focusedDay = dateOnly(day);
    notifyListeners();
  }

  // листаем месяцы стрелками или свайпом
  void changePage(DateTime newFocusedDay) {
    focusedDay = dateOnly(newFocusedDay);
    notifyListeners();
  }

  void previousMonth() {
    changePage(DateTime(focusedDay.year, focusedDay.month - 1, 1));
  }

  void nextMonth() {
    // DateTime сам переносит 13-й месяц на январь следующего года
    changePage(DateTime(focusedDay.year, focusedDay.month + 1, 1));
  }

  void goToToday() {
    selectDay(DateTime.now());
  }

  // возвращает текст ошибки или null, если всё сохранилось
  String? addEvent({
    required String title,
    String description = '',
    required DateTime start,
    DateTime? end,
    EventCategory category = EventCategory.other,
  }) {
    String? error = _check(title, start, end);
    if (error != null) return error;

    repository.add(
      title: title.trim(),
      description: description.trim(),
      start: start,
      end: end,
      category: category,
    );
    // показываем день, на который добавили событие
    selectDay(start);
    return null;
  }

  String? updateEvent(Event event) {
    String? error = _check(event.title, event.start, event.end);
    if (error != null) return error;

    repository.update(event.copyWith(
      title: event.title.trim(),
      description: event.description.trim(),
    ));
    selectDay(event.start);
    return null;
  }

  void deleteEvent(String id) {
    repository.delete(id);
    notifyListeners();
  }

  String? _check(String title, DateTime start, DateTime? end) {
    if (title.trim().isEmpty) return 'Введите название события';
    return checkEventTime(start, end);
  }
}
