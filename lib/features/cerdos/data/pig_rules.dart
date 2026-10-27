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
  final limit = maxPlausibleWeightKg(days);
  if (pesoKg <= limit) return null;
  final edad = days == 1 ? '1 día' : '$days días';
  return 'Un cerdo de $edad de nacido normalmente no pesa más de '
      '${limit.round()} kg, y capturaste ${pesoKg.toStringAsFixed(pesoKg % 1 == 0 ? 0 : 1)} kg. '
      '¿Quieres revisar el peso o la fecha de nacimiento?';
}
