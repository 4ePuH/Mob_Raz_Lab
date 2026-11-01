import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/data/todo_repository.dart';
import 'package:todo_list/models/task.dart';
import 'package:todo_list/state/todo_state.dart';
import 'package:todo_list/utils/format.dart';

Future<TodoState> makeState() async {
  TodoState state = TodoState(TodoRepository());
  await state.load();
  return state;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('задача в json и обратно', () {
    Task t = Task(
      id: '1',
      title: 'Купить хлеб',
      description: 'бородинский',
      isDone: true,
      createdAt: DateTime(2026, 11, 1, 14, 5),
    );
    Task back = Task.fromJson(t.toJson());
    expect(back.id, '1');
    expect(back.title, 'Купить хлеб');
    expect(back.description, 'бородинский');
    expect(back.isDone, isTrue);
    expect(back.createdAt, DateTime(2026, 11, 1, 14, 5));
  });

  test('добавление задачи', () async {
    TodoState state = await makeState();
    expect(state.addTask('  Сделать лабу  ', ''), isTrue);
    expect(state.tasks.length, 1);
    // пробелы по краям обрезаются
    expect(state.tasks.first.title, 'Сделать лабу');
    expect(state.tasks.first.isDone, isFalse);
  });

  test('у задач, добавленных подряд, разные id', () async {
    TodoState state = await makeState();
    for (int i = 0; i < 20; i++) {
      state.addTask('Задача $i', '');
    }
    expect(state.tasks.map((t) => t.id).toSet().length, 20);
  });

  test('пустое название не сохраняется', () async {
    TodoState state = await makeState();
    expect(state.addTask('', 'описание'), isFalse);
    expect(state.addTask('    ', ''), isFalse);
    expect(state.tasks, isEmpty);
  });

  test('изменение названия', () async {
    TodoState state = await makeState();
    state.addTask('Старое', '');
    Task t = state.tasks.first;

    expect(state.updateTask(t.copyWith(title: 'Новое')), isTrue);
    expect(state.tasks.first.title, 'Новое');
    // id и дата создания не меняются
    expect(state.tasks.first.id, t.id);
    expect(state.tasks.first.createdAt, t.createdAt);

    // пустым сделать нельзя
    expect(state.updateTask(t.copyWith(title: ' ')), isFalse);
    expect(state.tasks.first.title, 'Новое');
  });

  test('отметка выполненной и обратно', () async {
    TodoState state = await makeState();
    state.addTask('Задача', '');
    String id = state.tasks.first.id;

    state.toggleDone(id);
    expect(state.tasks.first.isDone, isTrue);
    state.toggleDone(id);
    expect(state.tasks.first.isDone, isFalse);
  });

  test('удаление и отмена удаления', () async {
    TodoState state = await makeState();
    state.addTask('Задача', '');
    Task? removed = state.deleteTask(state.tasks.first.id);
    expect(removed, isNotNull);
    expect(state.tasks, isEmpty);

    state.restoreTask(removed!);
    expect(state.tasks.length, 1);
    expect(state.deleteTask('нет такого id'), isNull);
  });

  test('фильтры', () async {
    TodoState state = await makeState();
    state.addTask('Первая', '');
    state.addTask('Вторая', '');
    state.addTask('Третья', '');
    state.toggleDone(state.tasks[1].id);

    state.setFilter(TaskFilter.active);
    expect(state.visibleTasks.map((t) => t.title), unorderedEquals(['Первая', 'Третья']));

    state.setFilter(TaskFilter.done);
    expect(state.visibleTasks.map((t) => t.title), ['Вторая']);

    state.setFilter(TaskFilter.all);
    expect(state.visibleTasks.length, 3);
    expect(state.activeCount, 2);
    expect(state.doneCount, 1);
  });

  test('поиск по части названия без учёта регистра', () async {
    TodoState state = await makeState();
    state.addTask('Купить молоко', '');
    state.addTask('Позвонить маме', '');
    state.addTask('Молоток вернуть соседу', '');

    state.setQuery('МОЛО');
    expect(state.visibleTasks.length, 2);

    state.setQuery('маме');
    expect(state.visibleTasks.single.title, 'Позвонить маме');

    state.setQuery('');
    expect(state.visibleTasks.length, 3);
  });

  test('поиск работает вместе с фильтром', () async {
    TodoState state = await makeState();
    state.addTask('Купить молоко', '');
    state.addTask('Купить хлеб', '');
    state.toggleDone(state.tasks.first.id);

    state.setFilter(TaskFilter.active);
    state.setQuery('купить');
    expect(state.visibleTasks.single.title, 'Купить хлеб');
  });

  test('задачи сохраняются между запусками', () async {
    TodoState state = await makeState();
    state.addTask('Не забыть', 'важно');
    state.toggleDone(state.tasks.first.id);
    // сохранение асинхронное, даём ему закончиться
    await Future<void>.delayed(Duration.zero);

    TodoState again = await makeState();
    expect(again.tasks.length, 1);
    expect(again.tasks.first.title, 'Не забыть');
    expect(again.tasks.first.isDone, isTrue);
  });

  test('испорченные данные не роняют приложение', () async {
    SharedPreferences.setMockInitialValues({'tasks': 'это не json'});
    TodoState state = await makeState();
    expect(state.tasks, isEmpty);
  });

  test('формат даты', () {
    expect(formatDateTime(DateTime(2026, 3, 5, 9, 7)), '05.03.2026, 09:07');
  });
}
