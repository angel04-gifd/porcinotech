import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/config/app_config.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  // La conexión se guarda en el dispositivo (pantalla «Conecta tu granja»);
  // env.json con --dart-define-from-file es solo un valor inicial opcional.
  final config = await AppConfig.load();
  if (config != null) await initializeSupabase(config);

  runApp(
    RestartWidget(
      child: ProviderScope(
        overrides: [appConfigProvider.overrideWith((ref) => config)],
        child: const PorcinoTechApp(),
      ),
    ),
  );
}

/// Reinicia todo el estado de la app (la sesión se conserva). Se usa al cambiar
/// de granja para que ninguna pantalla muestre datos de la granja anterior.
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key, required this.child});
  final Widget child;

  static void restart(BuildContext context) =>
      context.findAncestorStateOfType<_RestartWidgetState>()?.restart();

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();
  void restart() => setState(() => _key = UniqueKey());

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

class PorcinoTechApp extends ConsumerWidget {
  const PorcinoTechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'PorcinoTech',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es'), Locale('en')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: _buildTheme(),
    routerConfig: ref.watch(appRouterProvider),
  );
}

/// Verde de campo como base; el rosa de cerdo se usa solo en el botón de
/// acción principal para que sea lo que más destaque.
ThemeData _buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xff176b4d),
  ).copyWith(
    tertiaryContainer: const Color(0xffffd9de),
    onTertiaryContainer: const Color(0xff5c1a26),
  );
  final radius = BorderRadius.circular(14);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      scrolledUnderElevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: scheme.outlineVariant),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.tertiaryContainer,
      foregroundColor: scheme.onTertiaryContainer,
      elevation: 1,
    ),
  );
}
