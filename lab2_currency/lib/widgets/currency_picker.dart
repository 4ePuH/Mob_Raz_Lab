import 'package:flutter/material.dart';

import '../models/currency.dart';
import '../state/converter_state.dart';

// Нижняя шторка со списком валют. Возвращает код выбранной валюты или null
Future<String?> showCurrencyPicker(BuildContext context, ConverterState state) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _CurrencyPicker(state: state),
  );
}

class _CurrencyPicker extends StatefulWidget {
  final ConverterState state;

  const _CurrencyPicker({required this.state});

  @override
  State<_CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<_CurrencyPicker> {
  String query = '';

  bool _matches(Currency c) {
    String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return c.code.toLowerCase().contains(q) || c.name.toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height * 0.75;

    return SizedBox(
      height: height,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Поиск: код или название',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (text) => setState(() => query = text),
            ),
          ),
          Expanded(
            // звёздочки меняются в state, поэтому слушаем его и тут
            child: ListenableBuilder(
              listenable: widget.state,
              builder: (context, _) {
                List<Currency> favorites =
                    widget.state.favoriteCurrencies.where(_matches).toList();
                List<Currency> others =
                    widget.state.otherCurrencies.where(_matches).toList();

                if (favorites.isEmpty && others.isEmpty) {
                  return const Center(child: Text('Ничего не найдено'));
                }

                return ListView(
                  children: [
                    if (favorites.isNotEmpty) const _SectionTitle('Избранные'),
                    for (Currency c in favorites) _tile(c),
                    if (others.isNotEmpty) const _SectionTitle('Все валюты'),
                    for (Currency c in others) _tile(c),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(Currency c) {
    bool fav = widget.state.isFavorite(c.code);
    return ListTile(
      leading: CircleAvatar(
        child: Text(c.code, style: const TextStyle(fontSize: 12)),
      ),
      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(c.code),
      trailing: IconButton(
        icon: Icon(fav ? Icons.star : Icons.star_border),
        color: fav ? Colors.amber : null,
        tooltip: fav ? 'Убрать из избранного' : 'В избранное',
        onPressed: () => widget.state.toggleFavorite(c.code),
      ),
      onTap: () => Navigator.pop(context, c.code),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        text,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
