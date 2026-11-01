import 'package:calendar_app/data/event_repository.dart';
import 'package:calendar_app/models/event.dart';
import 'package:calendar_app/state/calendar_state.dart';
import 'package:calendar_app/utils/format.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

CalendarState makeState() {
  return CalendarState(EventRepository(), initialDay: DateTime(2026, 11, 2));
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  group('даты', () {
    test('сравнение только по дню', () {
      expect(isSameDate(DateTime(2026, 11, 2, 23, 59), DateTime(2026, 11, 2)), isTrue);
      // table_calendar отдаёт дни в UTC - тоже должно совпадать
      expect(isSameDate(DateTime.utc(2026, 11, 2), DateTime(2026, 11, 2, 10)), isTrue);
      expect(isSameDate(DateTime(2026, 11, 2), DateTime(2026, 11, 3)), isFalse);
      expect(isSameDate(DateTime(2026, 11, 2), DateTime(2025, 11, 2)), isFalse);
    });

    test('проверка начала и окончания', () {
      DateTime start = DateTime(2026, 11, 2, 10);
      expect(checkEventTime(start, null), isNull);
      expect(checkEventTime(start, DateTime(2026, 11, 2, 11, 30)), isNull);
      expect(checkEventTime(start, DateTime(2026, 11, 2, 9)), isNotNull);
      // конец ровно в начало тоже нельзя
      expect(checkEventTime(start, start), isNotNull);
      expect(checkEventTime(start, DateTime(2026, 11, 3, 11)), isNotNull);
    });

    test('форматирование', () {
      expect(formatMonthTitle(DateTime(2026, 11, 1)), 'Ноябрь 2026');
      expect(formatTime(DateTime(2026, 11, 2, 9, 5)), '09:05');
      expect(formatDayTitle(DateTime(2026, 11, 2)), 'понедельник, 2 ноября');
    });
  });

  test('выбор даты', () {
    CalendarState state = makeState();
    state.selectDay(DateTime.utc(2026, 11, 15));
    expect(state.selectedDay, DateTime(2026, 11, 15));
    expect(state.selectedDay.isUtc, isFalse);
  });

  test('создание события', () {
    CalendarState state = makeState();
    String? error = state.addEvent(
      title: ' Пара по мобилкам ',
      start: DateTime(2026, 11, 2, 10, 10),
      end: DateTime(2026, 11, 2, 11, 40),
      category: EventCategory.study,
    );
    expect(error, isNull);
    expect(state.selectedEvents.length, 1);
    expect(state.selectedEvents.first.title, 'Пара по мобилкам');
    expect(state.selectedEvents.first.category, EventCategory.study);
  });

  test('событие без названия не сохраняется', () {
    CalendarState state = makeState();
    String? error = state.addEvent(title: '  ', start: DateTime(2026, 11, 2, 10));
    expect(error, 'Введите название события');
    expect(state.repository.getAll(), isEmpty);
  });

  test('конец раньше начала не сохраняется', () {
    CalendarState state = makeState();
    String? error = state.addEvent(
      title: 'Встреча',
      start: DateTime(2026, 11, 2, 15),
      end: DateTime(2026, 11, 2, 14),
    );
    expect(error, 'Окончание должно быть позже начала');
    expect(state.repository.getAll(), isEmpty);
  });

  test('несколько событий в один день идут по времени', () {
    CalendarState state = makeState();
    state.addEvent(title: 'Вечер', start: DateTime(2026, 11, 2, 19));
    state.addEvent(title: 'Утро', start: DateTime(2026, 11, 2, 8));
    state.addEvent(title: 'Обед', start: DateTime(2026, 11, 2, 13));
    state.addEvent(title: 'Другой день', start: DateTime(2026, 11, 3, 10));

    List<String> titles =
        state.eventsForDay(DateTime(2026, 11, 2)).map((e) => e.title).toList();
    expect(titles, ['Утро', 'Обед', 'Вечер']);
    expect(state.eventsForDay(DateTime.utc(2026, 11, 3)).length, 1);
    expect(state.eventsForDay(DateTime(2026, 11, 4)), isEmpty);
  });

  test('редактирование события, перенос на другой день', () {
    CalendarState state = makeState();
    state.addEvent(title: 'Старое', start: DateTime(2026, 11, 2, 10));
    Event e = state.selectedEvents.first;

    String? error = state.updateEvent(e.copyWith(
      title: 'Новое',
      start: DateTime(2026, 11, 5, 12),
    ));
    expect(error, isNull);
    expect(state.eventsForDay(DateTime(2026, 11, 2)), isEmpty);
    expect(state.eventsForDay(DateTime(2026, 11, 5)).single.title, 'Новое');
    // после сохранения выбран день события
    expect(state.selectedDay, DateTime(2026, 11, 5));
  });

  test('редактирование: можно убрать время окончания', () {
    CalendarState state = makeState();
    state.addEvent(
      title: 'Встреча',
      start: DateTime(2026, 11, 2, 10),
      end: DateTime(2026, 11, 2, 11),
    );
    Event e = state.selectedEvents.first;
    state.updateEvent(e.copyWith(clearEnd: true));
    expect(state.selectedEvents.first.end, isNull);
  });

  test('удаление события', () {
    CalendarState state = makeState();
    state.addEvent(title: 'Первое', start: DateTime(2026, 11, 2, 10));
    state.addEvent(title: 'Второе', start: DateTime(2026, 11, 2, 11));
    state.deleteEvent(state.selectedEvents.first.id);
    expect(state.selectedEvents.single.title, 'Второе');
  });

  test('переход между месяцами, в том числе через новый год', () {
    CalendarState state = CalendarState(
      EventRepository(),
      initialDay: DateTime(2026, 12, 20),
    );
    state.nextMonth();
    expect(state.focusedDay, DateTime(2027, 1, 1));
    state.previousMonth();
    state.previousMonth();
    expect(state.focusedDay, DateTime(2026, 11, 1));
    // выбранный день при листании не меняется
    expect(state.selectedDay, DateTime(2026, 12, 20));
  });
}
