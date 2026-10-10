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

  testWidgets('все кнопки на месте', (WidgetTester tester) async {
    await tester.pumpWidget(const CalculatorApp());
    expect(find.byType(CalcButton), findsNWidgets(19));
    expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
  });
}
