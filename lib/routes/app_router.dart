import 'package:distribucionesgp/screens/login_screen.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/home_screen.dart';
import '../screens/other_screen.dart';
import 'package:distribucionesgp/screens/settings_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'init',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      name: "distribucion",
      path: "/distribucion/:id", // <-- Añade :id aquí
      builder: (context, state) {
        // Recuperamos el parámetro 'id' de la URL o estado
        final idTransferencia = state.pathParameters['id'] ?? '';
        return OtherScreen(idTransferencia: idTransferencia);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
