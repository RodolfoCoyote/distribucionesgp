import 'dart:async'; // Necesario para el Timer
import 'package:distribucionesgp/provider/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
// Importa tu pantalla de inicio aquí
// import 'package:tu_app/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    // Espera mínimo 1 segundo
    await Future.delayed(const Duration(seconds: 1));

    // Espera a que termine la carga real
    final auth = Provider.of<AuthProvider>(context, listen: false);

    while (auth.isInitializing) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    if (kDebugMode) {
      print('Usuario en SplashScreen: ${auth.user}');
      print('¿Está logueado?: ${auth.isAuthenticated}');
    }

    if (!mounted) return;

    if (auth.isAuthenticated) {
      context.pushReplacementNamed('home');
    } else {
      context.pushReplacementNamed('login');
    }
  }

  @override
  Widget build(BuildContext context) {
    const gpBlue = Color(0xFF00A3FF);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Imagen central
          Center(child: Image.asset('assets/logo.jpeg', width: 50)),

          // Footer con Loader y Versión
          Positioned(
            bottom: 60,
            left: 50,
            right: 50,
            child: Column(
              children: [
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  child: LinearProgressIndicator(
                    backgroundColor: Color(0xFFF2F2F2),
                    valueColor: AlwaysStoppedAnimation<Color>(gpBlue),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "v 0.0.3",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
