import 'package:calculator/logic/calculator_logic.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // чтобы короче писать
  String calc(List<String> tokens) {
    return CalculatorLogic.formatNumber(CalculatorLogic.calculate(tokens));
  }

  test('простые операции', () {
    expect(calc(['12', '+', '8']), '20');
    expect(calc(['15', '−', '7']), '8');
    expect(calc(['6', '×', '7']), '42');
    expect(calc(['20', '÷', '4']), '5');
  });

  test('десятичные числа', () {
    expect(calc(['12.5', '+', '0.5']), '13');
    expect(calc(['0.1', '+', '0.2']), '0.3');
    expect(calc(['1', '÷', '3']), '0.3333333333');
  });

  test('сначала умножение, потом сложение', () {
    expect(calc(['2', '+', '3', '×', '4']), '14');
    expect(calc(['10', '−', '6', '÷', '2', '+', '1']), '8');
  });

  test('отрицательные числа', () {
    expect(calc(['-5', '+', '3']), '-2');
    expect(calc(['8', '×', '-2']), '-16');
  });

  test('деление на ноль', () {
    expect(
      () => CalculatorLogic.calculate(['5', '÷', '0']),
      throwsA(isA<CalculatorException>()),
    );
  });

  test('неполное выражение', () {
    expect(
      () => CalculatorLogic.calculate(['5', '+']),
      throwsA(isA<CalculatorException>()),
    );
  });
}
