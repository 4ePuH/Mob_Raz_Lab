import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/converter_state.dart';
import '../utils/format.dart';
import '../widgets/currency_button.dart';
import '../widgets/currency_picker.dart';

class ConverterScreen extends StatefulWidget {
  final ConverterState state;

  const ConverterScreen({super.key, required this.state});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final TextEditingController amountController = TextEditingController();

  ConverterState get state => widget.state;

  @override
  void initState() {
    super.initState();
    // запрос делаем один раз при открытии экрана, а не в build()
    state.init();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  Future<void> pickFrom() async {
    String? code = await showCurrencyPicker(context, state);
    if (code != null) state.setFrom(code);
  }

  Future<void> pickTo() async {
    String? code = await showCurrencyPicker(context, state);
    if (code != null) state.setTo(code);
  }

  void onConvert() {
    FocusScope.of(context).unfocus();
    state.convert();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Конвертер валют'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Обновить курсы',
            onPressed: state.loadRates,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          // курсов ещё нет совсем - показываем только загрузку или ошибку
          if (state.rates == null) {
            if (state.status == LoadStatus.error) {
              return _ErrorView(
                message: state.loadError ?? 'Ошибка',
                onRetry: state.loadRates,
              );
            }
            return const _LoadingView();
          }
          return _buildContent(context);
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      children: [
        // курсы есть, но обновляются - тонкая полоска сверху
        if (state.status == LoadStatus.loading) const LinearProgressIndicator(),
        if (state.status == LoadStatus.error)
          MaterialBanner(
            content: Text('Не удалось обновить курсы: ${state.loadError}'),
            actions: [
              TextButton(
                onPressed: state.loadRates,
                child: const Text('Повторить'),
              ),
            ],
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  // буквы не даём ввести вообще, остальное проверит state
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\- ]')),
                  ],
                  style: const TextStyle(fontSize: 24),
                  decoration: InputDecoration(
                    labelText: 'Сумма',
                    border: const OutlineInputBorder(),
                    errorText: state.inputError,
                    suffixText: state.fromCode,
                  ),
                  onChanged: state.setAmount,
                  onSubmitted: (_) => onConvert(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CurrencyButton(
                        label: 'Из',
                        currency: state.from,
                        isFavorite: state.isFavorite(state.fromCode),
                        onTap: pickFrom,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: 'Поменять местами',
                      onPressed: state.swap,
                    ),
                    Expanded(
                      child: CurrencyButton(
                        label: 'В',
                        currency: state.to,
                        isFavorite: state.isFavorite(state.toCode),
                        onTap: pickTo,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onConvert,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Конвертировать'),
                ),
                const SizedBox(height: 16),
                if (state.result != null) _ResultCard(state: state),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  final ConverterState state;

  const _ResultCard({required this.state});

  @override
  Widget build(BuildContext context) {
    TextTheme text = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${formatMoney(state.resultAmount!)} ${state.fromCode} =',
              style: text.titleMedium,
            ),
            const SizedBox(height: 4),
            // длинные числа уменьшаем, чтобы не вылезали за экран
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '${formatMoney(state.result!)} ${state.toCode}',
                style: text.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Divider(height: 24),
            Text('1 ${state.fromCode} = ${formatMoney(state.rate!)} ${state.toCode}'),
            const SizedBox(height: 4),
            Text(
              'Курс ЦБ РФ на ${formatDate(state.rates!.date)}',
              style: text.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Загружаем курсы...'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
