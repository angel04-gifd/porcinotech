import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/features/cerdos/data/pig_rules.dart';

void main() {
  final hoy = DateTime(2026, 11, 3);

  test('un lechón de 18 días tiene referencia de pocos kilos', () {
    final ref = pesoReferenciaPorEdad(DateTime(2026, 10, 16), hoy: hoy)!;
    expect(ref.dias, 18);
    expect(ref.minKg, closeTo(4.8, 0.1));
    expect(ref.maxKg, closeTo(7.7, 0.1));
  });

  test('sin fecha, con fecha futura o muy adulto no hay referencia', () {
    expect(pesoReferenciaPorEdad(null, hoy: hoy), isNull);
    expect(pesoReferenciaPorEdad(DateTime(2026, 11, 10), hoy: hoy), isNull);
    expect(pesoReferenciaPorEdad(DateTime(2025, 1, 1), hoy: hoy), isNull);
  });

  test('la referencia crece con la edad y nunca supera el peso máximo creíble', () {
    var anterior = 0.0;
    for (var dias = 0; dias <= 180; dias += 10) {
      final ref = pesoReferenciaPorEdad(
        DateTime(2026, 11, 3).subtract(Duration(days: dias)),
        hoy: hoy,
      )!;
      expect(ref.minKg, greaterThanOrEqualTo(anterior));
      expect(ref.maxKg, lessThanOrEqualTo(maxPlausibleWeightKg(dias)));
      anterior = ref.minKg;
    }
  });
}
