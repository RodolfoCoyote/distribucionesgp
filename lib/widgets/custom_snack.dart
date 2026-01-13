import 'package:flutter/material.dart';

class CustomSnack {
  static void show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Color textColor = Colors.white,
  }) {
    // Limpia snacks anteriores para que no se amontonen
    ScaffoldMessenger.of(context).removeCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor:
            Colors.transparent, // Fondo transparente para usar nuestro diseño
        elevation: 0,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // MÉTODO SUCCESS (Verde)
  static void success(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF2E7D32),
      icon: Icons.check_circle_outline,
    );
  }

  // MÉTODO DANGER (Rojo)
  static void danger(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFFD32F2F),
      icon: Icons.error_outline,
    );
  }

  // MÉTODO WARNING (Naranja/Amarillo)
  static void warning(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFFFFA000),
      icon: Icons.warning_amber_rounded,
    );
  }

  // MÉTODO INFO (Negro y Blanco como pediste)
  static void info(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF1A1A1A), // Negro GamePlanet
      icon: Icons.info_outline,
      textColor: Colors.white,
    );
  }
}
