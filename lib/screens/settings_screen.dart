import 'package:distribucionesgp/provider/auth_provider.dart';
import 'package:distribucionesgp/widgets/bottom_nav/user_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    await authProvider.logout();

    if (!mounted) return;

    context.pushReplacementNamed('login');
  }

  @override
  Widget build(BuildContext context) {
    const gpBlue = Color(0xFF00A3FF);
    const textMain = Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      appBar: AppBar(
        title: const Text(
          'Configuración',
          style: TextStyle(color: textMain, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: textMain),
      ),
      body: Center(
        //Logout
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: gpBlue,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          onPressed: () {
            _logout();
          },
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
      bottomNavigationBar: UserBottomNav(currentIndex: 1),
    );
  }
}
