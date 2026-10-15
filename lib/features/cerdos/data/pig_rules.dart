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
