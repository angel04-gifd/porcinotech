/// Peso máximo aceptado para un cerdo, en kg.
const maxPigWeightKg = 500;

/// Valida el texto del peso (coma o punto decimal). Vacío es válido.
String? validatePigWeight(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final weight = double.tryParse(text.replaceAll(',', '.'));
  if (weight == null) return 'Peso inválido';
  if (weight < 0) return 'El peso no puede ser negativo';
  if (weight > maxPigWeightKg) return 'El peso máximo es $maxPigWeightKg kg';
  return null;
}

/// Un corral admite otro cerdo activo solo si no está lleno.
bool penHasRoom({required int capacity, required int activeResidents}) =>
    activeResidents < capacity;

/// Peso máximo razonable para la edad: ~2 kg al nacer y hasta ~1.3 kg de
/// ganancia por día (ya engordando bien), sin pasar de [maxPigWeightKg].
double maxPlausibleWeightKg(int ageDays) {
  final limit = 2 + ageDays * 1.3;
  return limit > maxPigWeightKg ? maxPigWeightKg.toDouble() : limit;
}

/// Aviso (no bloquea) cuando el peso no cuadra con la edad, por ejemplo un
/// cerdo de 6 días con 77 kg. Devuelve null si no hay datos o todo es creíble.
String? pesoIncoherenteConEdad({
  required double? pesoKg,
  required DateTime? nacimiento,
  DateTime? hoy,
}) {
  if (pesoKg == null || nacimiento == null) return null;
  final now = hoy ?? DateTime.now();
  final days = DateTime(now.year, now.month, now.day)
      .difference(DateTime(nacimiento.year, nacimiento.month, nacimiento.day))
      .inDays;
  if (days < 0) return null;
  final edad = days == 1 ? '1 día' : '$days días';
  final capturado =
      pesoKg.toStringAsFixed(pesoKg % 1 == 0 ? 0 : 1);
  // Hasta los 180 días se compara con el rango de referencia; después, solo
  // con el máximo creíble.
  final referencia = pesoReferenciaPorEdad(nacimiento, hoy: now);
  if (referencia != null) {
    if (pesoKg <= referencia.maxKg) return null;
    return 'Un cerdo de $edad de nacido normalmente pesa entre '
        '${referencia.minKg.toStringAsFixed(1)} y '
        '${referencia.maxKg.toStringAsFixed(1)} kg, y capturaste $capturado kg. '
        '¿Quieres revisar el peso o la fecha de nacimiento?';
  }
  final limit = maxPlausibleWeightKg(days);
  if (pesoKg <= limit) return null;
  return 'Un cerdo de $edad de nacido normalmente no pesa más de '
      '${limit.round()} kg, y capturaste $capturado kg. '
      '¿Quieres revisar el peso o la fecha de nacimiento?';
}

/// Peso de referencia (aproximado) de un cerdo según sus días de nacido.
class PesoReferencia {
  const PesoReferencia({
    required this.dias,
    required this.minKg,
    required this.maxKg,
  });

  final int dias;
  final double minKg;
  final double maxKg;
}

/// Curva orientativa de crecimiento: ~1.5 kg al nacer, ~8.5 kg a los 28 días,
/// ~27 kg a los 70 y ~87 kg a los 150. El rango es ±20 % (más 0.5 kg arriba). Después de 180 días
/// el peso varía mucho (engorda, reproductores) y no se da referencia.
PesoReferencia? pesoReferenciaPorEdad(DateTime? nacimiento, {DateTime? hoy}) {
  if (nacimiento == null) return null;
  final now = hoy ?? DateTime.now();
  final dias = DateTime(now.year, now.month, now.day)
      .difference(DateTime(nacimiento.year, nacimiento.month, nacimiento.day))
      .inDays;
  if (dias < 0 || dias > 180) return null;
  final double esperado;
  if (dias <= 28) {
    esperado = 1.5 + 0.25 * dias;
  } else if (dias <= 70) {
    esperado = 8.5 + 0.45 * (dias - 28);
  } else if (dias <= 150) {
    esperado = 27.4 + 0.75 * (dias - 70);
  } else {
    esperado = 87.4 + 0.85 * (dias - 150);
  }
  final maxKg = esperado * 1.2 + 0.5; // margen para camadas pesadas
  final limite = maxPlausibleWeightKg(dias);
  return PesoReferencia(
    dias: dias,
    minKg: esperado * 0.8,
    maxKg: maxKg > limite ? limite : maxKg,
  );
}
