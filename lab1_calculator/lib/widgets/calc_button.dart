import 'package:flutter/material.dart';

// digit - цифры и точка, operator - знаки (оранжевые), function - C, ⌫, +/-
enum ButtonType { digit, operator, function }

class CalcButton extends StatelessWidget {
  final String text;
  final ButtonType type;
  final VoidCallback onPressed;
  // если задана иконка, рисуем её вместо текста
  final IconData? icon;

  const CalcButton({
    super.key,
    required this.text,
    required this.type,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;

    Color background;
    Color textColor;
    if (type == ButtonType.operator) {
      background = const Color(0xFFFF9F0A);
      textColor = Colors.white;
    } else if (type == ButtonType.function) {
      background = isDark ? const Color(0xFF4A4A4F) : const Color(0xFFD4D4D8);
      textColor = isDark ? Colors.white : Colors.black;
    } else {
      background = isDark ? const Color(0xFF2C2C2E) : Colors.white;
      textColor = isDark ? Colors.white : Colors.black;
    }

    Widget content;
    if (icon != null) {
      content = Icon(icon, color: textColor, size: 28);
    } else {
      content = Text(text, style: TextStyle(fontSize: 30, color: textColor));
    }

    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Center(
            // если кнопка маленькая (например экран повёрнут), текст уменьшится
            child: FittedBox(fit: BoxFit.scaleDown, child: content),
          ),
        ),
      ),
    );
  }
}
