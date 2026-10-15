import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/presentation/login_screen.dart';
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
      final authState = ref.read(authStateProvider);
      final isLogin = state.matchedLocation == '/login';

      if (authState.isLoading) {
        return isLogin ? null : '/login';
      }

      final loggedIn = authState.valueOrNull?.session != null;
      if (!loggedIn && !isLogin) return '/login';
      if (loggedIn && isLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
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
  ref.onDispose(router.dispose);
  return router;
});
