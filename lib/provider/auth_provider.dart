import 'dart:convert';

import 'package:distribucionesgp/models/empleado_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final _storage = const FlutterSecureStorage();

  EmpleadoModel? _user;
  String? _token;
  bool _isInitializing = true; // Para saber si estamos cargando datos del disco

  // Getters para acceder desde cualquier lado
  EmpleadoModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null;
  bool get isInitializing => _isInitializing;

  // 1. MÉTODO PARA CARGAR DATOS AL INICIAR LA APP
  Future<void> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();

    _token = await _storage.read(key: 'auth_token');
    final userRaw = prefs.getString('user_data');

    if (_token != null && userRaw != null) {
      _user = EmpleadoModel.fromJson(jsonDecode(userRaw));
    }

    _isInitializing = false;
    notifyListeners();
  }

  // Función para guardar los datos al loguearse
  Future<void> setAuthData(EmpleadoModel user, String token) async {
    _user = user;
    _token = token;

    // Guardamos el token de forma persistente y segura
    await _storage.write(key: 'auth_token', value: token);

    // Guardamos el usuario en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(user.toJson()));

    // Avisamos a los widgets que algo cambió (como el estado de React)
    notifyListeners();
  }

  // Para borrar todo al cerrar sesión
  Future<void> logout() async {
    _user = null;
    _token = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
