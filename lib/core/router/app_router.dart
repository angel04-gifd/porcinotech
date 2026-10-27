import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/reset_password_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/farms/presentation/farm_setup_screen.dart';
import '../../features/alimentos/presentation/foods_screen.dart';
import '../../features/cerdos/presentation/cerdos_screen.dart';
import '../../features/corrales/presentation/corrales_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/partos/presentation/partos_screen.dart';
import '../../features/partos/presentation/upcoming_farrowings_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../widgets/main_layout.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final location = state.matchedLocation;

      final authState = ref.read(authStateProvider);
      final isLogin = location == '/login';

      if (authState.isLoading) {
        return isLogin ? null : '/login';
      }

      final loggedIn = authState.valueOrNull?.session != null;
      if (!loggedIn && location == '/recuperar') return null;
      if (!loggedIn && !isLogin) return '/login';
      if (!loggedIn) return null;

      // Con sesión, hay que saber si la cuenta ya tiene granja ANTES de mostrar
      // el inicio; si no, la pantalla principal aparece unos segundos y luego
      // salta a elegir administrador u operador.
      final profileState = ref.read(currentProfileProvider);
      final profile = profileState.valueOrNull;
      if (profileState.isLoading && profile == null && location != '/recuperar') {
        return location == '/cargando' ? null : '/cargando';
      }
      // Sin granja activa (cuenta nueva) toca crear una o unirse con código.
      if (profile != null &&
          profile.containsKey('granja_id') &&
          profile['granja_id'] == null &&
          location != '/granja') {
        return '/granja';
      }
      if (isLogin || location == '/cargando') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/cargando',
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(path: '/granja', builder: (_, _) => const FarmSetupScreen()),
      GoRoute(
        path: '/recuperar',
        builder: (_, _) => const ResetPasswordScreen(),
      ),
      ShellRoute(
        builder: (_, _, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(path: '/cerdos', builder: (_, _) => const CerdosScreen()),
          GoRoute(path: '/corrales', builder: (_, _) => const CorralesScreen()),
          GoRoute(path: '/partos', builder: (_, _) => const PartosScreen()),
          GoRoute(
            path: '/partos/proximos',
            builder: (_, _) => const UpcomingFarrowingsScreen(),
          ),
          GoRoute(path: '/alimentos', builder: (_, _) => const FoodsScreen()),
          GoRoute(path: '/perfil', builder: (_, _) => const ProfileScreen()),
        ],
      ),
    ],
  );
  ref.listen(authStateProvider, (previous, next) => router.refresh());
  ref.listen(currentProfileProvider, (previous, next) => router.refresh());
  ref.onDispose(router.dispose);
  return router;
});
