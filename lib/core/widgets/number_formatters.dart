import 'package:flutter/services.dart';

/// Quita los ceros a la izquierda de un número que se escribe ("010" → "10",
/// "007.5" → "7.5"), pero deja "0", "0.5" y "0,25" como están.
String sinCerosIzquierda(String text) {
  final match = RegExp(r'^0+(?=\d)').firstMatch(text);
  return match == null ? text : text.substring(match.end);
}

class NoLeadingZerosFormatter extends TextInputFormatter {
  const NoLeadingZerosFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cleaned = sinCerosIzquierda(newValue.text);
    if (cleaned == newValue.text) return newValue;
    final removed = newValue.text.length - cleaned.length;
    final offset = (newValue.selection.baseOffset - removed).clamp(
      0,
      cleaned.length,
    );
    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}
