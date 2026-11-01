import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/event.dart';
import '../state/calendar_state.dart';
import '../utils/format.dart';
import 'event_edit_screen.dart';

class CalendarScreen extends StatelessWidget {
  final CalendarState state;

  const CalendarScreen({super.key, required this.state});

  // форму открываем новым маршрутом, выбранный день передаём через конструктор
  Future<void> addEvent(BuildContext context) async {
    EventDraft? draft = await Navigator.push<EventDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditScreen(initialDate: state.selectedDay),
      ),
    );
    if (draft == null) return;
    state.addEvent(
      title: draft.title,
      description: draft.description,
      start: draft.start,
      end: draft.end,
      category: draft.category,
    );
  }

  Future<void> editEvent(BuildContext context, Event event) async {
    EventDraft? draft = await Navigator.push<EventDraft>(
      context,
      MaterialPageRoute(
        builder: (_) => EventEditScreen(
          event: event,
          initialDate: event.start,
        ),
      ),
    );
    if (draft == null) return;
    state.updateEvent(event.copyWith(
      title: draft.title,
      description: draft.description,
      start: draft.start,
      end: draft.end,
      clearEnd: draft.end == null,
      category: draft.category,
    ));
  }

  Future<void> deleteEvent(BuildContext context, Event event) async {
    bool? ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить событие?'),
        content: Text('«${event.title}» будет удалено.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true) state.deleteEvent(event.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: 'Сегодня',
            onPressed: state.goToToday,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => addEvent(context),
        tooltip: 'Добавить событие',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          List<Event> events = state.selectedEvents;
          // всё в одном ListView, чтобы на маленьком экране календарь
          // и список прокручивались вместе и ничего не вылезало
          return ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              _buildCalendar(context),
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Text(
                  _capitalize(formatDayTitle(state.selectedDay)),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (events.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('На этот день событий нет')),
                ),
              for (Event e in events) _eventTile(context, e),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    ColorScheme colors = Theme.of(context).colorScheme;

    return TableCalendar<Event>(
      locale: 'ru_RU',
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2035, 12, 31),
      focusedDay: state.focusedDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      // переключатель месяц/2 недели не нужен, только месяц
      availableCalendarFormats: const {CalendarFormat.month: 'Месяц'},
      selectedDayPredicate: (day) => isSameDate(day, state.selectedDay),
      onDaySelected: (selected, focused) => state.selectDay(selected),
      onPageChanged: state.changePage,
      eventLoader: state.eventsForDay,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextFormatter: (date, locale) => formatMonthTitle(date),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        selectedDecoration: BoxDecoration(
          color: colors.primary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(color: colors.onPrimary),
      ),
      calendarBuilders: CalendarBuilders<Event>(
        // вместо одинаковых точек рисуем точки цвета категории
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return null;
          return Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (Event e in events.take(3))
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: e.category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _eventTile(BuildContext context, Event e) {
    return ListTile(
      // цветная полоска слева - категория
      leading: Container(
        width: 6,
        height: 40,
        decoration: BoxDecoration(
          color: e.category.color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${formatEventTime(e)} · ${e.category.label}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: 'Удалить',
        onPressed: () => deleteEvent(context, e),
      ),
      onTap: () => editEvent(context, e),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
