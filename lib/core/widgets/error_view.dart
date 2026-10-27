import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/resilient_stream.dart';

/// Texto claro en español para un error técnico (sin mostrar la excepción).
String friendlyError(Object error) {
  // Primero la sesión: un error de Realtime con "InvalidJWTToken" también
  // menciona RealtimeSubscribeException, pero la causa es la sesión vencida.
  if (isSessionError(error)) {
    return 'Tu sesión venció. Cierra sesión y vuelve a entrar.';
  }
  final text = error.toString().toLowerCase();
  final isNetwork =
      text.contains('socketexception') ||
      text.contains('clientexception') ||
      text.contains('timeoutexception') ||
      text.contains('failed host lookup') ||
      text.contains('connection closed') ||
      text.contains('connection refused') ||
      text.contains('connection reset') ||
      text.contains('retryablefetch') ||
      text.contains('timedout') ||
      text.contains('realtimesubscribeexception');
  if (isNetwork) {
    return 'No hay conexión con el servidor. Revisa tu internet e inténtalo de nuevo.';
  }
  if (error is PostgrestException) return _friendlyDatabaseError(error);
  return 'Ocurrió un problema inesperado. Inténtalo de nuevo.';
}

/// Las reglas de la base de datos (permisos, stock, "no existe"…) ya vienen
/// escritas en español; el resto de errores técnicos no se muestran.
String _friendlyDatabaseError(PostgrestException error) {
  final message = error.message.trim();
  final code = error.code ?? '';
  switch (code) {
    case '23505':
      return 'Ese dato ya está registrado.';
    case '23503':
      return 'No se puede completar porque está relacionado con otros registros.';
    case '42501':
      final technical =
          message.isEmpty ||
          message.toLowerCase().contains('row-level security') ||
          message.toLowerCase().startsWith('new row');
      return technical
          ? 'Tu rol no tiene permiso para hacer esto.'
          : message;
  }
  final isBusinessRule = (code.startsWith('P0') || code == '22023') &&
      message.isNotEmpty;
  if (isBusinessRule) {
    final missing = RegExp(r'^(El|La) .+ no existe\.$').hasMatch(message);
    return missing
        ? '$message Puede ser de otra granja: actualiza la lista y revisa '
              'cuál es tu granja activa.'
        : message;
  }
  return 'No se pudo completar la operación. Inténtalo de nuevo.';
}

/// Alerta de error con el motivo en español (nunca la excepción en crudo).
void showErrorSnackBar(BuildContext context, String title, Object error) {
  final scheme = Theme.of(context).colorScheme;
  final color = scheme.onErrorContainer;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.errorContainer,
        showCloseIcon: true,
        closeIconColor: color,
        duration: const Duration(seconds: 6),
        content: Row(
          children: [
            Icon(Icons.error_outline, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.w600),
                  ),
                  Text(friendlyError(error), style: TextStyle(color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
}

/// Aviso de error con el motivo en español y un botón para reintentar.
///
/// Con [compact] cabe dentro de una tarjeta o de un formulario.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.title,
    required this.error,
    this.onRetry,
    this.compact = false,
  });

  /// Qué no se pudo hacer, por ejemplo "No se pudieron cargar los cerdos".
  final String title;
  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final retry = onRetry == null
        ? null
        : FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          );
    final texts = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium,
          textAlign: compact ? TextAlign.start : TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          friendlyError(error),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: compact ? TextAlign.start : TextAlign.center,
        ),
      ],
    );

    if (compact) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            texts,
            if (retry != null) ...[const SizedBox(height: 8), retry],
          ],
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            texts,
            if (retry != null) ...[const SizedBox(height: 16), retry],
          ],
        ),
      ),
    );
  }
}
