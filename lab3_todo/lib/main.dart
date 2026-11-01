import 'package:flutter/material.dart';

import 'data/todo_repository.dart';
import 'screens/todo_screen.dart';
import 'state/todo_state.dart';

void main() {
  // TodoScreen -> TodoState -> TodoRepository
  TodoState state = TodoState(TodoRepository());
  runApp(TodoApp(state: state));
}

class TodoApp extends StatelessWidget {
  final TodoState state;

  const TodoApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Список задач',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: TodoScreen(state: state),
    );
  }
}
