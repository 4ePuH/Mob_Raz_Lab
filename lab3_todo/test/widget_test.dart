import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/data/todo_repository.dart';
import 'package:todo_list/main.dart';
import 'package:todo_list/state/todo_state.dart';

Future<void> openApp(WidgetTester tester) async {
  await tester.pumpWidget(TodoApp(state: TodoState(TodoRepository())));
  await tester.pumpAndSettle();
}

Future<void> addTask(WidgetTester tester, String title) async {
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextFormField).first, title);
  await tester.tap(find.text('Сохранить'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('пустой список', (tester) async {
    await openApp(tester);
    expect(find.textContaining('Задач пока нет'), findsOneWidget);
  });

  testWidgets('добавление задачи через форму', (tester) async {
    await openApp(tester);
    await addTask(tester, 'Сдать лабу');

    expect(find.text('Сдать лабу'), findsOneWidget);
    expect(find.textContaining('Создана'), findsOneWidget);
  });

  testWidgets('пустое название - ошибка, экран не закрывается', (tester) async {
    await openApp(tester);
    await addTask(tester, '   ');

    expect(find.text('Введите название задачи'), findsOneWidget);
    expect(find.text('Новая задача'), findsOneWidget);
  });

  testWidgets('редактирование по нажатию на задачу', (tester) async {
    await openApp(tester);
    await addTask(tester, 'Старое название');

    await tester.tap(find.text('Старое название'));
    await tester.pumpAndSettle();
    expect(find.text('Редактирование'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Новое название');
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Новое название'), findsOneWidget);
    expect(find.text('Старое название'), findsNothing);
  });

  testWidgets('выполнение, фильтр и удаление', (tester) async {
    await openApp(tester);
    await addTask(tester, 'Первая');
    await addTask(tester, 'Вторая');

    // отмечаем "Первая" выполненной
    Finder firstTile = find.ancestor(
      of: find.text('Первая'),
      matching: find.byType(ListTile),
    );
    await tester.tap(find.descendant(of: firstTile, matching: find.byType(Checkbox)));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Активные (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Первая'), findsNothing);
    expect(find.text('Вторая'), findsOneWidget);

    await tester.tap(find.text('Выполненные (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Первая'), findsOneWidget);
    expect(find.text('Вторая'), findsNothing);

    await tester.tap(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('Первая'), findsNothing);
    expect(find.text('Отменить'), findsOneWidget);
  });

  testWidgets('поиск', (tester) async {
    await openApp(tester);
    await addTask(tester, 'Купить молоко');
    await addTask(tester, 'Позвонить маме');

    await tester.enterText(find.byType(TextField).first, 'молоко');
    await tester.pumpAndSettle();
    expect(find.text('Купить молоко'), findsOneWidget);
    expect(find.text('Позвонить маме'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'xyz');
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
  });

  testWidgets('влезает на маленький экран', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await openApp(tester);
    await addTask(tester, 'Очень длинное название задачи, которое точно не влезет в одну строку на маленьком экране');
    await addTask(tester, 'Ещё одна');

    expect(tester.takeException(), isNull);
  });
}
