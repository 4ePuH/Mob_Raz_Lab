import 'package:calculator/logic/calculator_state.dart';
import 'package:flutter_test/flutter_test.dart';

// нажимает кнопки по очереди, как пользователь
CalculatorState pressAll(List<String> buttons) {
  CalculatorState calc = CalculatorState();
  for (String b in buttons) {
    calc.press(b);
  }
  return calc;
}

void main() {
  // сценарии из пункта 8 методички
  test('12 + 8 = 20', () {
    var calc = pressAll(['1', '2', '+', '8', '=']);
    expect(calc.bottomLine, '20');
    expect(calc.topLine, '12 + 8 =');
  });

  test('15 − 7 = 8', () {
    expect(pressAll(['1', '5', '−', '7', '=']).bottomLine, '8');
  });

  test('6 × 7 = 42', () {
    expect(pressAll(['6', '×', '7', '=']).bottomLine, '42');
  });

  test('20 ÷ 4 = 5', () {
    expect(pressAll(['2', '0', '÷', '4', '=']).bottomLine, '5');
  });

  test('5 ÷ 0 - ошибка', () {
    var calc = pressAll(['5', '÷', '0', '=']);
    expect(calc.error, isNotNull);
    expect(calc.bottomLine, 'На ноль делить нельзя');
  });

  test('12.5 + 0.5 = 13', () {
    expect(pressAll(['1', '2', '.', '5', '+', '0', '.', '5', '=']).bottomLine, '13');
  });

  // остальное
  test('после ошибки можно сразу считать дальше', () {
    var calc = pressAll(['5', '÷', '0', '=', '2', '+', '2', '=']);
    expect(calc.error, isNull);
    expect(calc.bottomLine, '4');
  });

  test('две точки в числе не ставятся', () {
    expect(pressAll(['1', '.', '.', '5']).bottomLine, '1.5');
  });

  test('точка в начале превращается в 0.', () {
    expect(pressAll(['.', '5']).bottomLine, '0.5');
  });

  test('нет ведущих нулей', () {
    expect(pressAll(['0', '0', '7']).bottomLine, '7');
  });

  test('два знака подряд - остаётся последний', () {
    expect(pressAll(['5', '+', '×', '2']).bottomLine, '5 × 2');
  });

  test('знак в конце при "=" отбрасывается', () {
    expect(pressAll(['5', '+', '3', '×', '=']).bottomLine, '8');
  });

  test('после "=" знак продолжает от результата', () {
    expect(pressAll(['2', '+', '3', '=', '×', '4', '=']).bottomLine, '20');
  });

  test('после "=" цифра начинает заново', () {
    expect(pressAll(['2', '+', '3', '=', '7']).bottomLine, '7');
  });

  test('C очищает всё', () {
    expect(pressAll(['1', '2', '+', '3', 'C']).bottomLine, '0');
  });

  test('⌫ стирает последний символ', () {
    expect(pressAll(['1', '2', '3', '⌫']).bottomLine, '12');
    expect(pressAll(['1', '2', '+', '⌫']).bottomLine, '12');
    expect(pressAll(['5', '⌫']).bottomLine, '0');
  });

  test('+/- меняет знак числа', () {
    expect(pressAll(['5', '+/-']).bottomLine, '-5');
    expect(pressAll(['5', '+/-', '+/-']).bottomLine, '5');
    expect(pressAll(['8', '×', '+/-', '2']).bottomLine, '8 × (-2)');
    expect(pressAll(['8', '×', '+/-', '2', '=']).bottomLine, '-16');
  });

  test('история: новые сверху, ошибки не попадают', () {
    var calc = pressAll(['1', '+', '1', '=', '5', '÷', '0', '=', '2', '×', '3', '=']);
    expect(calc.history, ['2 × 3 = 6', '1 + 1 = 2']);
  });

  test('история не больше 20 записей и C её не трогает', () {
    var calc = CalculatorState();
    for (int i = 0; i < 25; i++) {
      for (String b in ['1', '+', '1', '=']) {
        calc.press(b);
      }
    }
    calc.press('C');
    expect(calc.history.length, CalculatorState.maxHistory);
    calc.clearHistory();
    expect(calc.history, isEmpty);
  });

  test('слишком длинное число не набирается', () {
    var buttons = List.filled(20, '9');
    expect(pressAll(buttons).bottomLine.length, CalculatorState.maxDigits);
  });
}
