import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

// Хранилище задач (доп. задание - локальное сохранение).
// Весь список лежит одной строкой JSON под одним ключом,
// для учебного списка задач этого хватает
class TodoRepository {
  static const String _key = 'tasks';

  Future<List<Task>> loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? raw = prefs.getString(_key);
    if (raw == null) return [];

    try {
      List<dynamic> list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      // если сохранённые данные испорчены, лучше начать с пустого списка, чем упасть
      return [];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String raw = jsonEncode(tasks.map((t) => t.toJson()).toList());
    await prefs.setString(_key, raw);
  }
}
