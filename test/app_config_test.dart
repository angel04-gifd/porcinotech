import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/core/config/app_config.dart';
import 'package:porcinotech/features/dashboard/data/weather_repository.dart';

void main() {
  test('La app carga una configuración pública por defecto', () async {
    final config = await AppConfig.load();
    expect(config, isNotNull);
    expect(config!.url, startsWith('https://'));
    expect(config.anonKey.startsWith('sb_secret_'), isFalse);
  });

  test('El estrés por calor usa la sensación térmica', () {
    expect(heatLevelFor(8), HeatLevel.cold);
    expect(heatLevelFor(22), HeatLevel.comfort);
    expect(heatLevelFor(29), HeatLevel.caution);
    expect(heatLevelFor(35), HeatLevel.danger);
  });
}
