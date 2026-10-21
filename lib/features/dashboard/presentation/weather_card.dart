import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/weather_repository.dart';

class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(weatherPlaceProvider);
    final weather = ref.watch(weatherProvider);
    final theme = Theme.of(context);

    Widget body(Widget leading, String title, String subtitle) => ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: IconButton(
        tooltip: 'Cambiar ubicación',
        icon: const Icon(Icons.edit_location_alt_outlined),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (_) => const _PlaceDialog(),
        ),
      ),
    );

    return Card(
      child: weather.when(
        loading: () => body(
          const SizedBox.square(
            dimension: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          'Clima en ${place.name}',
          'Consultando el clima...',
        ),
        error: (_, _) => ListTile(
          leading: const Icon(Icons.cloud_off_outlined),
          title: Text('Clima en ${place.name}'),
          subtitle: const Text('No se pudo consultar el clima. Revisa tu internet.'),
          trailing: IconButton(
            tooltip: 'Reintentar',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(weatherProvider),
          ),
        ),
        data: (data) {
          final level = heatLevelFor(data.apparentTemperature);
          final color = switch (level) {
            HeatLevel.cold => theme.colorScheme.primary,
            HeatLevel.comfort => theme.colorScheme.primary,
            HeatLevel.caution => Colors.orange.shade800,
            HeatLevel.danger => theme.colorScheme.error,
          };
          return body(
            Icon(Icons.thermostat, color: color, size: 32),
            '${data.temperature.round()} °C en ${place.name}',
            'Sensación ${data.apparentTemperature.round()} °C · '
            'Humedad ${data.humidity.round()} % · '
            'Hoy ${data.minTemperature.round()}–${data.maxTemperature.round()} °C\n'
            '${heatAdvice(level)}',
          );
        },
      ),
    );
  }
}

class _PlaceDialog extends ConsumerStatefulWidget {
  const _PlaceDialog();
  @override
  ConsumerState<_PlaceDialog> createState() => _PlaceDialogState();
}

class _PlaceDialogState extends ConsumerState<_PlaceDialog> {
  final _query = TextEditingController();
  List<WeatherPlace> _results = const [];
  bool _searching = false;
  String? _message;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    if (_query.text.trim().length < 2) return;
    setState(() {
      _searching = true;
      _message = null;
    });
    try {
      final found = await searchPlaces(_query.text);
      if (!mounted) return;
      setState(() {
        _results = found;
        _message = found.isEmpty ? 'No se encontró ese lugar.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _message = 'No se pudo buscar. Revisa tu internet.');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Ubicación de la granja'),
    content: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _query,
            autofocus: true,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              labelText: 'Municipio o ciudad',
              suffixIcon: IconButton(
                tooltip: 'Buscar',
                icon: const Icon(Icons.search),
                onPressed: _searching ? null : _search,
              ),
            ),
          ),
          if (_searching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          if (_message != null)
            Padding(padding: const EdgeInsets.all(12), child: Text(_message!)),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                for (final place in _results)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(place.name),
                    onTap: () {
                      ref.read(weatherPlaceProvider.notifier).setPlace(place);
                      Navigator.of(context).pop();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Cerrar'),
      ),
    ],
  );
}
