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
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b4d)),
      useMaterial3: true,
    ),
    routerConfig: ref.watch(appRouterProvider),
  );
}
