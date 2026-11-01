import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/todo_state.dart';
import '../widgets/task_tile.dart';
import 'task_edit_screen.dart';

class TodoScreen extends StatefulWidget {
  final TodoState state;

  const TodoScreen({super.key, required this.state});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TextEditingController searchController = TextEditingController();

  TodoState get state => widget.state;

  @override
  void initState() {
    super.initState();
    state.load();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // открываем форму новым маршрутом и ждём, что она вернёт
  Future<void> addTask() async {
    TaskDraft? draft = await Navigator.push<TaskDraft>(
      context,
      MaterialPageRoute(builder: (_) => const TaskEditScreen()),
    );
    if (draft != null) {
      state.addTask(draft.title, draft.description);
    }
  }

  Future<void> editTask(Task task) async {
    TaskDraft? draft = await Navigator.push<TaskDraft>(
      context,
      MaterialPageRoute(builder: (_) => TaskEditScreen(task: task)),
    );
    if (draft != null) {
      state.updateTask(
        task.copyWith(title: draft.title, description: draft.description),
      );
    }
  }

  void deleteTask(Task task) {
    Task? removed = state.deleteTask(task.id);
    if (removed == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Задача «${removed.title}» удалена'),
          action: SnackBarAction(
            label: 'Отменить',
            onPressed: () => state.restoreTask(removed),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Мои задачи')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addTask,
        icon: const Icon(Icons.add),
        label: const Text('Задача'),
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _buildSearch(),
              _buildFilters(),
              const Divider(height: 1),
              Expanded(child: _buildList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Поиск по названию',
          prefixIcon: const Icon(Icons.search),
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: state.query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Очистить',
                  onPressed: () {
                    searchController.clear();
                    state.setQuery('');
                  },
                ),
        ),
        onChanged: state.setQuery,
      ),
    );
  }

  Widget _buildFilters() {
    // Wrap, а не Row: на узком экране чипы просто перенесутся на новую строку
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _filterChip('Все', state.tasks.length, TaskFilter.all),
            _filterChip('Активные', state.activeCount, TaskFilter.active),
            _filterChip('Выполненные', state.doneCount, TaskFilter.done),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, int count, TaskFilter value) {
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: state.filter == value,
      onSelected: (_) => state.setFilter(value),
    );
  }

  Widget _buildList() {
    List<Task> tasks = state.visibleTasks;

    if (tasks.isEmpty) {
      String text;
      if (state.tasks.isEmpty) {
        text = 'Задач пока нет.\nНажмите «Задача», чтобы добавить первую';
      } else if (state.query.trim().isNotEmpty) {
        text = 'Ничего не найдено';
      } else {
        text = 'В этом фильтре задач нет';
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(text, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.builder(
      // снизу отступ, чтобы последнюю задачу не закрывала кнопка
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: tasks.length,
      itemBuilder: (context, i) {
        Task task = tasks[i];
        return TaskTile(
          task: task,
          onToggle: () => state.toggleDone(task.id),
          onTap: () => editTask(task),
          onDelete: () => deleteTask(task),
        );
      },
    );
  }
}
