import '../models/event.dart';

// В базовой версии события хранятся только в памяти,
// после перезапуска приложения они пропадут
class EventRepository {
  final List<Event> _events = [];
  int _idCounter = 0;

  List<Event> getAll() => List.unmodifiable(_events);

  // события одного дня, отсортированные по времени начала
  List<Event> getForDay(DateTime day) {
    List<Event> list = _events.where((e) => e.isOnDay(day)).toList();
    list.sort((a, b) => a.start.compareTo(b.start));
    return list;
  }

  Event add({
    required String title,
    String description = '',
    required DateTime start,
    DateTime? end,
    EventCategory category = EventCategory.other,
  }) {
    _idCounter++;
    Event event = Event(
      id: '${DateTime.now().microsecondsSinceEpoch}_$_idCounter',
      title: title,
      description: description,
      start: start,
      end: end,
      category: category,
    );
    _events.add(event);
    return event;
  }

  bool update(Event event) {
    int index = _events.indexWhere((e) => e.id == event.id);
    if (index == -1) return false;
    _events[index] = event;
    return true;
  }

  bool delete(String id) {
    int before = _events.length;
    _events.removeWhere((e) => e.id == id);
    return _events.length < before;
  }
}
