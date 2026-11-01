import 'package:flutter/foundation.dart';

import '../data/todo_repository.dart';
import '../models/task.dart';

enum TaskFilter { all, active, done }

// Состояние списка: сами задачи, выбранный фильтр и строка поиска.
// Экраны сюда только обращаются, сами список не меняют
class TodoState extends ChangeNotifier {
  final TodoRepository repository;

  TodoState(this.repository);

  List<Task> tasks = [];
  TaskFilter filter = TaskFilter.all;
  String query = '';
  bool isLoading = true;

  Future<void> load() async {
    isLoading = true;
    notifyListeners();
    tasks = await repository.loadTasks();
    isLoading = false;
    notifyListeners();
  }

  // то, что видно на экране после фильтра и поиска, новые сверху
  List<Task> get visibleTasks {
    String q = query.trim().toLowerCase();
    List<Task> result = tasks.where((t) {
      if (filter == TaskFilter.active && t.isDone) return false;
      if (filter == TaskFilter.done && !t.isDone) return false;
      if (q.isNotEmpty && !t.title.toLowerCase().contains(q)) return false;
      return true;
    }).toList();
    result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  int get activeCount => tasks.where((t) => !t.isDone).length;
  int get doneCount => tasks.where((t) => t.isDone).length;

  void setFilter(TaskFilter value) {
    filter = value;
    notifyListeners();
  }

  void setQuery(String value) {
    query = value;
    notifyListeners();
  }

  int _idCounter = 0;

  // одного времени мало: на Windows две задачи подряд получали одинаковый id,
  // поэтому добавляем счётчик
  String _newId() {
    _idCounter++;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  // форма уже проверяет название, но на всякий случай проверяем и тут
  bool addTask(String title, String description) {
    if (title.trim().isEmpty) return false;
    tasks.add(Task(
      id: _newId(),
      title: title.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    ));
    _changed();
    return true;
  }

  bool updateTask(Task updated) {
    if (updated.title.trim().isEmpty) return false;
    int index = tasks.indexWhere((t) => t.id == updated.id);
    if (index == -1) return false;
    tasks[index] = updated;
    _changed();
    return true;
  }

  void toggleDone(String id) {
    int index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;
    tasks[index] = tasks[index].copyWith(isDone: !tasks[index].isDone);
    _changed();
  }

  // возвращаем удалённую задачу, чтобы можно было нажать "Отменить"
  Task? deleteTask(String id) {
    int index = tasks.indexWhere((t) => t.id == id);
    if (index == -1) return null;
    Task removed = tasks.removeAt(index);
    _changed();
    return removed;
  }

  void restoreTask(Task task) {
    tasks.add(task);
    _changed();
  }

  // после любого изменения перерисовываем экран и сохраняем
  void _changed() {
    notifyListeners();
    repository.saveTasks(tasks);
  }
}
