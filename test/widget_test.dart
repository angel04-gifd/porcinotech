import 'package:flutter_test/flutter_test.dart';
import 'package:porcinotech/features/cerdos/data/pig_repository.dart';
import 'package:porcinotech/features/cerdos/data/pig_rules.dart';
import 'package:porcinotech/features/partos/data/farrowing_repository.dart';

void main() {
  test('La FEPA suma 114 días de calendario', () {
    expect(dueDateFor(DateTime(2026, 1, 1)), DateTime(2026, 4, 25));
    expect(dueDateFor(DateTime(2026, 10, 1)), DateTime(2027, 1, 23));
  });

  test('El arete es consecutivo de 4 dígitos', () {
    expect(PigRepository.nextEarTag([]), '0001');
    expect(PigRepository.nextEarTag(['0001', '0007', 'X']), '0008');
  });

  test('Solo cuenta como gestante la cerda sin parto real', () {
    final rows = [
      {
        'cerda_id': 'a',
        'fecha_monta': '2026-01-01',
        'fecha_parto': '2026-04-25',
      },
      {'cerda_id': 'a', 'fecha_monta': '2026-06-01', 'fecha_parto': null},
      {
        'cerda_id': 'b',
        'fecha_monta': '2026-02-01',
        'fecha_parto': '2026-05-26',
      },
    ];
    expect(pendingFarrowingFor('a', rows)?['fecha_monta'], '2026-06-01');
    expect(pendingFarrowingFor('b', rows), isNull);
  });

  test('Una gestación fallida libera a la cerda', () {
    final rows = [
      {
        'cerda_id': 'a',
        'fecha_monta': '2026-06-01',
        'fecha_parto': null,
        'fallida': true,
      },
    ];
    expect(pendingFarrowingFor('a', rows), isNull);
    expect(isPendingFarrowing(rows.first), isFalse);
    expect(
      isPendingFarrowing({'fecha_parto': null, 'fallida': false}),
      isTrue,
    );
  });

  test('El parto real exige al menos 100 días desde la monta', () {
    expect(earliestBirthDate(DateTime(2026, 1, 1)), DateTime(2026, 4, 11));
    expect(earliestBirthDate(DateTime(2026, 1, 1)).isBefore(dueDateFor(DateTime(2026, 1, 1))), isTrue);
  });

  test('El peso se valida entre 0 y 500 kg', () {
    expect(validatePigWeight(''), isNull);
    expect(validatePigWeight(null), isNull);
    expect(validatePigWeight('85,5'), isNull);
    expect(validatePigWeight('500'), isNull);
    expect(validatePigWeight('-5'), isNotNull);
    expect(validatePigWeight('501'), isNotNull);
    expect(validatePigWeight('abc'), isNotNull);
  });

  test('Un corral lleno no admite más cerdos', () {
    expect(penHasRoom(capacity: 5, activeResidents: 4), isTrue);
    expect(penHasRoom(capacity: 5, activeResidents: 5), isFalse);
    expect(penHasRoom(capacity: 5, activeResidents: 7), isFalse);
  });
}
