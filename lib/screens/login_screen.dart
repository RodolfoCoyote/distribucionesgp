import 'package:distribucionesgp/api/api_service.dart';
import 'package:distribucionesgp/models/empleado_model.dart';
import 'package:distribucionesgp/provider/auth_provider.dart';
import 'package:distribucionesgp/widgets/custom_snack.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loading_elevated_button/loading_elevated_button.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Cambia esto a true cuando el usuario escriba algo
  bool hasUnsavedChanges = true;

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Espera'),
            content: const Text(
              'Al salir, se limpiará el historial de escaneos, ',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false), // No sale
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, true), // Confirma salida
                child: const Text(
                  'Descartar',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false; // Si cierran el diálogo tocando fuera, devolver false
  }

  final TextEditingController idController = TextEditingController();
  final TextEditingController keyController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  void _handleLogin() async {
    // 1. Validación inicial
    if (idController.text.isEmpty || keyController.text.isEmpty) {
      CustomSnack.info(context, "Por favor, completa todos los campos.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final api = Provider.of<ApiService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final response = await api.login({
        'id_empleado': idController.text,
        'password': keyController.text,
      });

      if (!mounted) return;

      // 2. Manejo de error de comunicación (4xx, 5xx)
      if (!response.isSuccessful) {
        final errorData = response.error as Map<String, dynamic>?;
        final mensaje =
            errorData?['message'] ??
            "Error de servidor (${response.statusCode})";

        CustomSnack.danger(context, mensaje);
        setState(() => _isLoading = false);
        return;
      }

      // 3. Manejo de respuesta exitosa (200) pero con lógica de negocio fallida
      final body = response.body as Map<String, dynamic>?;

      if (body == null || body['success'] == false) {
        String message = body?['message'] ?? "Respuesta inválida del servidor";
        CustomSnack.info(context, message);
        setState(() => _isLoading = false);
        return;
      }

      // 4. Extracción de datos (Aquí ya sabemos que success es true y body no es null)
      // Según tu JSON, los datos del empleado y el token vienen dentro de 'data'
      final data = body['data'];

      if (kDebugMode) {
        print("Datos recibidos: $data");
      }

      if (data != null && data is Map<String, dynamic>) {
        final EmpleadoModel empleado = EmpleadoModel.fromJson(data);
        final String token =
            data['token'] ?? ""; // Asegúrate que el token venga en data

        await authProvider.setAuthData(empleado, token);

        setState(() => _isLoading = false);
        if (!mounted) return;
        context.pushReplacementNamed('home');
      } else {
        throw Exception("El formato de 'data' no es válido");
      }
    } catch (e) {
      if (mounted) {
        if (kDebugMode) {
          print("Error durante el login: $e");
        }
        CustomSnack.danger(context, "Error inesperado: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const gpBlue = Color(0xFF00A3FF);

    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog();

        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F2F2), // Fondo gris de la app
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Campo ID
                TextField(
                  decoration: InputDecoration(
                    labelText: "ID de Empleado",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: idController,
                ),
                const SizedBox(height: 16),

                // Campo Clave POS
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Clave POS",
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  controller: keyController,
                ),
                const SizedBox(height: 32),

                // Botón Iniciar Sesión
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: LoadingElevatedButton(
                    isLoading: _isLoading,
                    disabledWhileLoading: true,
                    onPressed: () {
                      _handleLogin();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gpBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Iniciar Sesión",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
