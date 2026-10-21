import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Datos del proyecto de Supabase al que se conecta la app.
///
/// Van dentro de la app: quien instala el APK no ve ni configura nada, solo
/// inicia sesión. La clave es la pública (publishable/anon), diseñada para
/// viajar en la app; los datos los protege RLS en la base de datos.
/// NUNCA pongas aquí una clave secreta (sb_secret_ / service_role).
///
/// Para apuntar a otro proyecto sin tocar el código:
/// `flutter run --dart-define-from-file=env.json` (ver env.example.json).
class AppConfig {
  const AppConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;

  static const _buildUrl = String.fromEnvironment('SUPABASE_URL');
  static const _buildAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _defaultUrl = 'https://funqskosdhfoxdrdekqr.supabase.co';
  static const _defaultKey = 'sb_publishable_l7h6wsWt5B3i7G9aeo9mkw_7N9iCgVf';

  static Future<AppConfig?> load() async {
    final url = _buildUrl.isNotEmpty ? _buildUrl : _defaultUrl;
    final key = _buildAnonKey.isNotEmpty ? _buildAnonKey : _defaultKey;
    if (_isSecret(key)) {
      throw StateError('La app no admite claves secretas de Supabase.');
    }
    return AppConfig(url: url, anonKey: key);
  }

  static bool _isSecret(String key) =>
      key.startsWith('sb_secret_') || key.contains('service_role');
}

final appConfigProvider = StateProvider<AppConfig?>((ref) => null);

bool _supabaseReady = false;
bool get supabaseReady => _supabaseReady;

Future<void> initializeSupabase(AppConfig config) async {
  await Supabase.initialize(url: config.url, publishableKey: config.anonKey);
  _supabaseReady = true;
}
