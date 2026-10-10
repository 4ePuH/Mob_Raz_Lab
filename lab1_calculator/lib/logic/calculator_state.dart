import 'calculator_logic.dart';

// Состояние калькулятора: что сейчас набрано, какой результат, есть ли ошибка.
// Экран вызывает press() внутри setState, а потом просто рисует topLine и bottomLine
class CalculatorState {
  // набранное выражение, например ['12', '+', '8']
  List<String> tokens = [];
  String result = '';
  String? error;
  // true сразу после нажатия "="
  bool justCalculated = false;

  static const int maxDigits = 15;

  // сюда приходит текст нажатой кнопки
  void press(String button) {
    switch (button) {
      case 'C':
        clear();
      case '⌫':
        backspace();
      case '+/-':
        toggleSign();
      case '=':
        pressEquals();
      case '.':
        pressDot();
      default:
        if (CalculatorLogic.isOperator(button)) {
          pressOperator(button);
        } else {
          pressDigit(button);
        }
    }
  }

  void clear() {
    tokens = [];
    result = '';
    error = null;
    justCalculated = false;
  }

  bool get _lastIsNumber {
    return tokens.isNotEmpty && !CalculatorLogic.isOperator(tokens.last);
  }

  // после "=" продолжаем считать от результата: 20 -> "20 + ..."
  void _continueFromResult() {
    tokens = [result];
    result = '';
    justCalculated = false;
  }

  void pressDigit(String digit) {
    // после ошибки или "=" начинаем новое выражение
    if (error != null || justCalculated) {
      clear();
    }

    if (!_lastIsNumber) {
      tokens.add(digit);
      return;
    }

    String number = tokens.last;
    int digitsCount = number.replaceAll('-', '').replaceAll('.', '').length;
    if (digitsCount >= maxDigits) {
      return;
    }

    // чтобы не было чисел типа 05
    if (number == '0') {
      number = digit;
    } else if (number == '-0') {
      number = '-$digit';
    } else {
      number = number + digit;
    }
    tokens[tokens.length - 1] = number;
  }

  void pressDot() {
    if (error != null || justCalculated) {
      clear();
    }

    if (!_lastIsNumber) {
      tokens.add('0.');
      return;
    }

    // вторая точка в одном числе не нужна
    if (tokens.last.contains('.')) {
      return;
    }
    tokens[tokens.length - 1] = '${tokens.last}.';
  }

  void pressOperator(String op) {
    if (error != null) {
      clear();
      return;
    }
    if (justCalculated) {
      _continueFromResult();
    }

    if (tokens.isEmpty) {
      // на экране был 0, от него и считаем
      tokens.add('0');
    }

    if (CalculatorLogic.isOperator(tokens.last)) {
      // два знака подряд - просто заменяем последний
      tokens[tokens.length - 1] = op;
    } else {
      _removeDotAtEnd();
      tokens.add(op);
    }
  }

  void pressEquals() {
    if (error != null || justCalculated || tokens.isEmpty) {
      return;
    }

    // если в конце висит знак (например "12 +"), просто убираем его
    if (CalculatorLogic.isOperator(tokens.last)) {
      tokens.removeLast();
    }
    _removeDotAtEnd();

    // одно число считать нечего
    if (tokens.length < 3) {
      return;
    }

    try {
      double value = CalculatorLogic.calculate(tokens);
      result = CalculatorLogic.formatNumber(value);
      justCalculated = true;
    } on CalculatorException catch (e) {
      error = e.message;
    }
  }

  void backspace() {
    if (error != null || justCalculated) {
      clear();
      return;
    }
    if (tokens.isEmpty) {
      return;
    }

    String last = tokens.last;
    if (CalculatorLogic.isOperator(last) || last.length == 1) {
      tokens.removeLast();
      return;
    }

    String cut = last.substring(0, last.length - 1);
    if (cut == '-') {
      // от "-5" остался один минус, убираем число целиком
      tokens.removeLast();
    } else {
      tokens[tokens.length - 1] = cut;
    }
  }

  void toggleSign() {
    if (error != null) {
      clear();
    }
    if (justCalculated) {
      _continueFromResult();
    }

    // если числа ещё нет, начинаем отрицательное
    if (!_lastIsNumber) {
      tokens.add('-0');
      return;
    }

    String number = tokens.last;
    if (number.startsWith('-')) {
      number = number.substring(1);
    } else {
      number = '-$number';
    }
    tokens[tokens.length - 1] = number;
  }

  // "5." -> "5"
  void _removeDotAtEnd() {
    if (_lastIsNumber && tokens.last.endsWith('.')) {
      tokens[tokens.length - 1] =
          tokens.last.substring(0, tokens.last.length - 1);
    }
  }

  // выражение для показа на экране
  String get expressionText {
    List<String> parts = [];
    for (int i = 0; i < tokens.length; i++) {
      String t = tokens[i];
      // отрицательное число после знака берём в скобки: 8 × (-2)
      if (i > 0 && t.startsWith('-')) {
        parts.add('($t)');
      } else {
        parts.add(t);
      }
    }
    return parts.join(' ');
  }

  // верхняя строка, мелкая
  String get topLine {
    if (error != null) {
      return expressionText;
    }
    if (justCalculated) {
      return '$expressionText =';
    }
    return '';
  }

  // нижняя строка, крупная
  String get bottomLine {
    if (error != null) {
      return error!;
    }
    if (justCalculated) {
      return result;
    }
    if (tokens.isEmpty) {
      return '0';
    }
    return expressionText;
  }
}
