import 'package:calendar_app/data/event_repository.dart';
import 'package:calendar_app/main.dart';
import 'package:calendar_app/models/event.dart';
import 'package:calendar_app/state/calendar_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<CalendarState> openApp(WidgetTester tester) async {
  CalendarState state = CalendarState(
    EventRepository(),
    initialDay: DateTime(2026, 11, 2),
  );
  await tester.pumpWidget(CalendarApp(state: state));
  await tester.pumpAndSettle();
  return state;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru_RU');
  });

  testWidgets('заголовок месяца и выбранный день', (tester) async {
    await openApp(tester);
    expect(find.text('Ноябрь 2026'), findsOneWidget);
    expect(find.text('Понедельник, 2 ноября'), findsOneWidget);
    expect(find.text('На этот день событий нет'), findsOneWidget);
  });

  testWidgets('выбор другого дня', (tester) async {
    await openApp(tester);
    await tester.tap(find.text('15'));
    await tester.pumpAndSettle();
    expect(find.text('Воскресенье, 15 ноября'), findsOneWidget);
  });

  testWidgets('следующий и предыдущий месяц', (tester) async {
    await openApp(tester);
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    expect(find.text('Декабрь 2026'), findsOneWidget);

    // между нажатиями ждём, пока доиграет анимация листания
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('Октябрь 2026'), findsOneWidget);
  });

  testWidgets('создание события через форму', (tester) async {
    await openApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(find.text('Новое событие'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'Защита лабы');
    await tester.tap(find.text('Учёба'));
    await tester.pump();
    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Защита лабы'), findsOneWidget);
    expect(find.text('09:00 – 10:00 · Учёба'), findsOneWidget);
  });

  testWidgets('без названия не сохраняется', (tester) async {
    await openApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Введите название события'), findsOneWidget);
    expect(find.text('Новое событие'), findsOneWidget);
  });

  testWidgets('событие без времени окончания', (tester) async {
    await openApp(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Позвонить');
    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(find.text('Окончание'), findsNothing);

    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('09:00 · Работа'), findsOneWidget);
  });

  testWidgets('редактирование и удаление', (tester) async {
    CalendarState state = await openApp(tester);
    state.addEvent(
      title: 'Старое название',
      start: DateTime(2026, 11, 2, 12),
      category: EventCategory.personal,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Старое название'));
    await tester.pumpAndSettle();
    expect(find.text('Редактирование'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Новое название');
    await tester.tap(find.byTooltip('Сохранить'));
    await tester.pumpAndSettle();
    expect(find.text('Новое название'), findsOneWidget);

    // список под календарём, в тестовом окне событие ниже края экрана
    await tester.ensureVisible(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Удалить'));
    await tester.pumpAndSettle();
    expect(find.text('Удалить событие?'), findsOneWidget);
    await tester.tap(find.text('Удалить').last);
    await tester.pumpAndSettle();
    expect(find.text('Новое название'), findsNothing);
    expect(find.text('На этот день событий нет'), findsOneWidget);
  });

  testWidgets('влезает на маленький экран', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    CalendarState state = await openApp(tester);
    for (int i = 0; i < 4; i++) {
      state.addEvent(
        title: 'Событие с длинным названием номер $i, чтобы проверить перенос',
        start: DateTime(2026, 11, 2, 9 + i),
        end: DateTime(2026, 11, 2, 10 + i),
        category: EventCategory.values[i],
      );
    }
    await tester.pumpAndSettle();

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
