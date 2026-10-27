import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Clima de la granja con la API pública de Open-Meteo (no requiere clave).
class WeatherPlace {
  const WeatherPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;

  static const defaultPlace = WeatherPlace(
    name: 'Ixmiquilpan, Hidalgo',
    latitude: 20.4836,
    longitude: -99.2169,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory WeatherPlace.fromJson(Map<String, dynamic> json) => WeatherPlace(
    name: json['name'] as String,
    latitude: (json['latitude'] as num).toDouble(),
    longitude: (json['longitude'] as num).toDouble(),
  );
}

class Weather {
  const Weather({
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.maxTemperature,
    required this.minTemperature,
  });

  final double temperature;
  final double apparentTemperature;
  final double humidity;
  final double maxTemperature;
  final double minTemperature;
}

enum HeatLevel { cold, comfort, caution, danger }

/// Referencia general para cerdos: el confort ronda los 15-26 °C; sobre 27 °C
/// empieza el estrés por calor. Usa la sensación térmica, que incluye humedad.
HeatLevel heatLevelFor(double apparentTemperature) {
  if (apparentTemperature < 12) return HeatLevel.cold;
  if (apparentTemperature < 27) return HeatLevel.comfort;
  if (apparentTemperature < 32) return HeatLevel.caution;
  return HeatLevel.danger;
}

String heatAdvice(HeatLevel level) => switch (level) {
  HeatLevel.cold =>
    'Frío: protege a los lechones y a las cerdas recién paridas.',
  HeatLevel.comfort => 'Temperatura cómoda para los cerdos.',
  HeatLevel.caution =>
    'Calor: ventila los corrales y ofrece agua fresca en abundancia.',
  HeatLevel.danger =>
    'Estrés por calor: sombra, agua, mojar a los animales y alimentar en horas frescas.',
};

final weatherPlaceProvider =
    NotifierProvider<WeatherPlaceNotifier, WeatherPlace>(
      WeatherPlaceNotifier.new,
    );

class WeatherPlaceNotifier extends Notifier<WeatherPlace> {
  static const _prefsKey = 'weather_place';

  @override
  WeatherPlace build() {
    _load();
    return WeatherPlace.defaultPlace;
  }

  Future<void> _load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_prefsKey);
      if (raw != null) {
        state = WeatherPlace.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      }
    } catch (_) {
      // Se conserva la ubicación predeterminada.
    }
  }

  Future<void> setPlace(WeatherPlace place) async {
    state = place;
    try {
      await (await SharedPreferences.getInstance()).setString(
        _prefsKey,
        jsonEncode(place.toJson()),
      );
    } catch (_) {}
  }
}

/// El clima se guarda unos minutos: al volver a Inicio se muestra el último
/// dato al instante en vez de consultar de nuevo. Cambiar la ubicación o
/// pulsar "Reintentar" (invalidate) sí lo vuelve a pedir.
const weatherCacheDuration = Duration(minutes: 10);

final weatherProvider = FutureProvider.autoDispose<Weather>((ref) {
  final link = ref.keepAlive();
  final timer = Timer(weatherCacheDuration, link.close);
  ref.onDispose(timer.cancel);
  return fetchWeather(ref.watch(weatherPlaceProvider));
});

Future<Weather> fetchWeather(WeatherPlace place) async {
  final response = await http
      .get(
        Uri.https('api.open-meteo.com', '/v1/forecast', {
          'latitude': '${place.latitude}',
          'longitude': '${place.longitude}',
          'current': 'temperature_2m,relative_humidity_2m,apparent_temperature',
          'daily': 'temperature_2m_max,temperature_2m_min',
          'timezone': 'auto',
          'forecast_days': '1',
        }),
      )
      .timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw StateError('El servicio del clima respondió ${response.statusCode}.');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final current = json['current'] as Map<String, dynamic>;
  final daily = json['daily'] as Map<String, dynamic>;
  double first(String key) => ((daily[key] as List).first as num).toDouble();
  return Weather(
    temperature: (current['temperature_2m'] as num).toDouble(),
    apparentTemperature: (current['apparent_temperature'] as num).toDouble(),
    humidity: (current['relative_humidity_2m'] as num).toDouble(),
    maxTemperature: first('temperature_2m_max'),
    minTemperature: first('temperature_2m_min'),
  );
}

Future<List<WeatherPlace>> searchPlaces(String query) async {
  final response = await http
      .get(
        Uri.https('geocoding-api.open-meteo.com', '/v1/search', {
          'name': query.trim(),
          'count': '6',
          'language': 'es',
          'format': 'json',
        }),
      )
      .timeout(const Duration(seconds: 12));
  if (response.statusCode != 200) {
    throw StateError('No se pudo buscar el lugar.');
  }
  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final results = (json['results'] as List?) ?? const [];
  return [
    for (final item in results.cast<Map<String, dynamic>>())
      WeatherPlace(
        name: [
          item['name'],
          item['admin1'],
          item['country'],
        ].whereType<String>().where((part) => part.isNotEmpty).join(', '),
        latitude: (item['latitude'] as num).toDouble(),
        longitude: (item['longitude'] as num).toDouble(),
      ),
  ];
}
