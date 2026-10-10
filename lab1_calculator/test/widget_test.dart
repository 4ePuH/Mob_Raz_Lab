import 'package:calculator/main.dart';
import 'package:calculator/widgets/calc_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> tapButton(WidgetTester tester, String text) async {
    await tester.tap(find.widgetWithText(CalcButton, text));
    await tester.pump();
  }

  testWidgets('считает 12 + 8 через кнопки', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (String b in ['1', '2', '+', '8', '=']) {
      await tapButton(tester, b);
    }

    expect(find.text('12 + 8 ='), findsOneWidget);
    expect(find.text('20'), findsOneWidget);
  });

  testWidgets('показывает ошибку при делении на ноль', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (String b in ['5', '÷', '0', '=']) {
      await tapButton(tester, b);
    }

    expect(find.text('На ноль делить нельзя'), findsOneWidget);
  });

  testWidgets('история открывается и показывает пример', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    for (String b in ['6', '×', '7', '=']) {
      await tapButton(tester, b);
    }
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();

    expect(find.text('6 × 7 = 42'), findsOneWidget);
  });

  testWidgets('тема переключается', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());

    // сначала тёмная, значит кнопка предлагает светлую
    expect(find.byIcon(Icons.light_mode), findsOneWidget);
    await tester.tap(find.byIcon(Icons.light_mode));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.dark_mode), findsOneWidget);
    BuildContext context = tester.element(find.byType(CalcButton).first);
    expect(Theme.of(context).brightness, Brightness.light);
  });

  // если что-то вылезет за границы экрана, flutter test сам упадёт с ошибкой overflow
  testWidgets('влезает на разные экраны', (WidgetTester tester) async {
    addTearDown(tester.view.reset);
    List<Size> sizes = [
      const Size(320, 568), // маленький телефон
      const Size(375, 812), // обычный телефон
      const Size(812, 375), // телефон боком
      const Size(768, 1024), // планшет
    ];

    for (Size size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(const CalculatorApp());

      // длинное выражение тоже должно влезть
      for (String b in ['9', '9', '9', '9', '9', '9', '9', '×', '8', '8', '8', '8', '8', '8']) {
        await tapButton(tester, b);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('все кнопки на месте', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());
    expect(find.byType(CalcButton), findsNWidgets(19));
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
  });
}
