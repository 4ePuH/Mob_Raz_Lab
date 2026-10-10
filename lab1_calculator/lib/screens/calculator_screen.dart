import 'package:flutter/material.dart';

import '../logic/calculator_logic.dart';
import '../logic/calculator_state.dart';
import '../widgets/calc_button.dart';

class CalculatorScreen extends StatefulWidget {
  final bool isDark;
  final VoidCallback onThemeChanged;

  const CalculatorScreen({
    super.key,
    required this.isDark,
    required this.onThemeChanged,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorState calc = CalculatorState();

  // кнопки по рядам сверху вниз
  final List<List<String>> buttonRows = [
    ['C', '⌫', '+/-', '÷'],
    ['7', '8', '9', '×'],
    ['4', '5', '6', '−'],
    ['1', '2', '3', '+'],
    ['0', '.', '='],
  ];

  void onButtonPressed(String text) {
    // меняем состояние внутри setState, чтобы Flutter перерисовал экран
    setState(() {
      calc.press(text);
    });
  }

  ButtonType getType(String text) {
    if (CalculatorLogic.isOperator(text) || text == '=') {
      return ButtonType.operator;
    }
    if (text == 'C' || text == '⌫' || text == '+/-') {
      return ButtonType.function;
    }
    return ButtonType.digit;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'История',
            onPressed: showHistory,
          ),
          IconButton(
            icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Сменить тему',
            onPressed: widget.onThemeChanged,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          // на широком экране (планшет, браузер) не растягиваем кнопки на всю ширину
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                // дисплей и кнопки делят высоту экрана как 2 к 5
                Expanded(flex: 2, child: buildDisplay()),
                Expanded(flex: 5, child: buildButtons()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // история открывается снизу шторкой
  void showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        if (calc.history.isEmpty) {
          return const SizedBox(
            height: 150,
            child: Center(child: Text('История пока пустая')),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                'История',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              trailing: TextButton(
                onPressed: () {
                  setState(() {
                    calc.clearHistory();
                  });
                  Navigator.pop(context);
                },
                child: const Text('Очистить'),
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: calc.history.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      calc.history[index],
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontSize: 20),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget buildDisplay() {
    bool hasError = calc.error != null;

    // Container с alignment растягивается на всю ширину, текст прижимается вправо
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // FittedBox уменьшает текст, если он не влезает в ширину экрана
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                calc.topLine,
                style: const TextStyle(fontSize: 28, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            flex: 2,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                calc.bottomLine,
                style: TextStyle(
                  fontSize: hasError ? 36 : 64,
                  color: hasError ? Colors.redAccent : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildButtons() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: buttonRows.map((row) => buildRow(row)).toList(),
      ),
    );
  }

  Widget buildRow(List<String> row) {
    return Expanded(
      child: Row(
        children: row.map((text) {
          return Expanded(
            // ноль шире в два раза, как на картинке в задании
            flex: text == '0' ? 2 : 1,
            child: CalcButton(
              text: text,
              type: getType(text),
              icon: text == '⌫' ? Icons.backspace_outlined : null,
              onPressed: () => onButtonPressed(text),
            ),
          );
        }).toList(),
      ),
    );
  }
}
