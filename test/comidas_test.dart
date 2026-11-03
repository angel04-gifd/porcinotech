import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/features/alimentos/data/feeding_rules.dart';

Map<String, dynamic> comida(String id, String? corral, String fecha, String hora) =>
    {'id': id, 'corral_id': corral, 'fecha': fecha, 'created_at': '${fecha}T$hora:00Z'};

void main() {
  test('el máximo son 3 comidas al día', () {
    expect(maxFeedingsPerDay, 3);
  });

  test('cuenta las comidas del día de un corral sin importar el alimento', () {
    final registros = [
      comida('1', 'a', '2026-11-03', '06'),
      comida('2', 'a', '2026-11-03', '12'),
      comida('3', 'b', '2026-11-03', '12'),
      comida('4', 'a', '2026-11-02', '18'),
      comida('5', null, '2026-11-03', '08'),
    ];
    expect(feedingsOn(registros, penId: 'a', fecha: '2026-11-03'), 2);
    expect(feedingsOn(registros, penId: 'b', fecha: '2026-11-03'), 1);
    expect(feedingsOn(registros, penId: null, fecha: '2026-11-03'), 1);
    expect(feedingsOn(registros, penId: 'c', fecha: '2026-11-03'), 0);
  });

  test('con 3 comidas no hay extras y con 5 sobran la 4.ª y la 5.ª', () {
    final tres = [
      for (var i = 0; i < 3; i++) comida('t$i', 'a', '2026-11-03', '0$i'),
    ];
    expect(extraFeedingIds(tres), isEmpty);

    final cinco = [
      for (var i = 0; i < 5; i++) comida('c$i', 'a', '2026-11-03', '0$i'),
    ];
    expect(extraFeedingIds(cinco), {'c3', 'c4'});
  });

  test('los extras se cuentan por corral y por día, no en total', () {
    final registros = [
      for (var i = 0; i < 3; i++) comida('a$i', 'a', '2026-11-03', '0$i'),
      for (var i = 0; i < 3; i++) comida('b$i', 'b', '2026-11-03', '0$i'),
      for (var i = 0; i < 3; i++) comida('d$i', 'a', '2026-11-02', '0$i'),
      comida('extra', 'a', '2026-11-03', '09'),
    ];
    expect(extraFeedingIds(registros), {'extra'});
  });

  test('la fecha se escribe año-mes-día con ceros', () {
    expect(feedingDateKey(DateTime(2026, 1, 5)), '2026-01-05');
  });
}
