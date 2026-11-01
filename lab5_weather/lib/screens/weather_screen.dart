import 'package:flutter/material.dart';

import '../models/weather.dart';
import '../state/weather_state.dart';
import '../utils/format.dart';
import '../widgets/current_weather_card.dart';
import '../widgets/forecast_list.dart';

class WeatherScreen extends StatefulWidget {
  final WeatherState state;

  const WeatherScreen({super.key, required this.state});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final TextEditingController cityController = TextEditingController();

  WeatherState get state => widget.state;

  @override
  void initState() {
    super.initState();
    // загрузка один раз при открытии, не в build()
    state.init();
  }

  @override
  void dispose() {
    cityController.dispose();
    super.dispose();
  }

  void search() {
    FocusScope.of(context).unfocus();
    state.search(cityController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Погода')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          return Column(
            children: [
              _buildSearchField(),
              Expanded(child: _buildBody(context)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: cityController,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Город, например Москва',
          prefixIcon: const Icon(Icons.location_city),
          border: const OutlineInputBorder(),
          errorText: state.inputError,
          suffixIcon: IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Найти',
            onPressed: search,
          ),
        ),
        onSubmitted: (_) => search(),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (state.status) {
      case WeatherStatus.initial:
        return const _Message(
          icon: Icons.travel_explore,
          text: 'Введите город, чтобы узнать погоду',
        );
      case WeatherStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case WeatherStatus.notFound:
        return _Message(
          icon: Icons.search_off,
          text: 'Город «${state.lastQuery}» не найден.\nПроверьте название',
        );
      case WeatherStatus.error:
        return _Message(
          icon: Icons.cloud_off,
          text: state.errorMessage ?? 'Ошибка',
          buttonText: 'Повторить',
          onPressed: state.retry,
        );
      case WeatherStatus.success:
        return _buildWeather(state.weather!);
    }
  }

  Widget _buildWeather(Weather weather) {
    // потянуть вниз - обновить
    return RefreshIndicator(
      onRefresh: state.retry,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          if (weather.fromCache)
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: ListTile(
                leading: const Icon(Icons.wifi_off),
                title: const Text('Нет связи с сервером'),
                subtitle: Text(
                  'Показаны сохранённые данные от ${formatLoadedAt(weather.loadedAt)}',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Повторить',
                  onPressed: state.retry,
                ),
              ),
            ),
          CurrentWeatherCard(weather: weather),
          const SizedBox(height: 8),
          ForecastList(days: weather.daily),
          if (!weather.fromCache)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Обновлено ${formatLoadedAt(weather.loadedAt)}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _Message({
    required this.icon,
    required this.text,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center),
            if (buttonText != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onPressed,
                icon: const Icon(Icons.refresh),
                label: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
