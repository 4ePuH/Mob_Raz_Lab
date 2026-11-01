import 'package:flutter/material.dart';

import '../models/currency.dart';

// Кнопка с выбранной валютой: подпись сверху, код крупно, название мелко
class CurrencyButton extends StatelessWidget {
  final String label;
  final Currency? currency;
  final bool isFavorite;
  final VoidCallback onTap;

  const CurrencyButton({
    super.key,
    required this.label,
    required this.currency,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    TextTheme text = Theme.of(context).textTheme;

    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        alignment: Alignment.centerLeft,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.labelSmall),
          Row(
            children: [
              // на узком экране (320px) иначе не влезает вместе со звёздочкой
              Flexible(
                child: Text(
                  currency?.code ?? '---',
                  style: text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                ),
              ),
              if (isFavorite)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.star, size: 16, color: Colors.amber),
                ),
              const Spacer(),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
          Text(
            currency?.name ?? '',
            style: text.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
