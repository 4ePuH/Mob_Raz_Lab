// Тут только вычисления, про кнопки и экран этот класс ничего не знает.
// На вход приходит выражение в виде списка: числа и знаки по очереди,
// например ['12', '+', '8'] или ['2', '+', '3', '×', '4']

class CalculatorException implements Exception {
  final String message;

  CalculatorException(this.message);

  @override
  String toString() => message;
}

class CalculatorLogic {
  static const String plus = '+';
  static const String minus = '−';
  static const String multiply = '×';
  static const String divide = '÷';

  // больше этого числа уже начинаются проблемы с точностью double
  static const double maxValue = 1e15;

  static bool isOperator(String s) {
    return s == plus || s == minus || s == multiply || s == divide;
  }

  // Считает выражение с приоритетом: сначала × и ÷, потом + и −
  static double calculate(List<String> tokens) {
    // правильное выражение: число, знак, число, знак, ..., число
    // значит длина всегда нечётная
    if (tokens.isEmpty || tokens.length % 2 == 0) {
      throw CalculatorException('Неполное выражение');
    }

    List<double> numbers = [];
    List<String> operators = [];
    for (int i = 0; i < tokens.length; i++) {
      if (i % 2 == 0) {
        double? n = double.tryParse(tokens[i]);
        if (n == null) {
          throw CalculatorException('Неверное число');
        }
        numbers.add(n);
      } else {
        if (!isOperator(tokens[i])) {
          throw CalculatorException('Неизвестная операция');
        }
        operators.add(tokens[i]);
      }
    }

    // 1) проходим по знакам и сразу считаем умножение и деление.
    // два числа заменяем на результат, знак удаляем
    int i = 0;
    while (i < operators.length) {
      String op = operators[i];
      if (op == multiply || op == divide) {
        double a = numbers[i];
        double b = numbers[i + 1];
        double res;
        if (op == multiply) {
          res = a * b;
        } else {
          if (b == 0) {
            throw CalculatorException('На ноль делить нельзя');
          }
          res = a / b;
        }
        numbers[i] = res;
        numbers.removeAt(i + 1);
        operators.removeAt(i);
        // i не увеличиваем, на это место сдвинулся следующий знак
      } else {
        i++;
      }
    }

    // 2) остались только + и −, считаем слева направо
    double result = numbers[0];
    for (int j = 0; j < operators.length; j++) {
      if (operators[j] == plus) {
        result += numbers[j + 1];
      } else {
        result -= numbers[j + 1];
      }
    }

    if (result.isNaN || result.isInfinite || result.abs() >= maxValue) {
      throw CalculatorException('Слишком большое число');
    }
    return result;
  }

  // Переводит число в строку для экрана: 20.0 -> "20", 0.1 + 0.2 -> "0.3"
  static String formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    // округляем до 10 знаков после точки, иначе вылезают хвосты
    // типа 0.30000000000000004
    String s = value.toStringAsFixed(10);
    while (s.endsWith('0')) {
      s = s.substring(0, s.length - 1);
    }
    if (s.endsWith('.')) {
      s = s.substring(0, s.length - 1);
    }
    if (s == '-0') {
      s = '0';
    }
    return s;
  }
}
