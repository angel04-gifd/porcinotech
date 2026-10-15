import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es');

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Faltan SUPABASE_URL o SUPABASE_ANON_KEY en las variables de compilación.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(const ProviderScope(child: PorcinoTechApp()));
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
