import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/network/api_client.dart';
import '../models/sesion_model.dart';
import '../services/auth_service.dart';

const _sesionKey = 'sesion_actual';

/// Estado global de sesion: quien esta logueado y con que perfil. Todas las
/// pantallas leen esto via Provider.of/context.watch (patron _Portero).
class AuthProvider extends ChangeNotifier {
  SesionActual? _sesion;
  bool _cargando = true;

  SesionActual? get sesion => _sesion;
  bool get cargando => _cargando;
  bool get autenticado => _sesion != null;
  String? get tipoUsuario => _sesion?.tipoUsuario;

  AuthProvider() {
    _restaurarSesion();
  }

  Future<void> _restaurarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final guardada = prefs.getString(_sesionKey);
    if (guardada != null) {
      try {
        final json = jsonDecode(guardada);
        // Valida que el token siga vigente antes de restaurar la sesion.
        // Si el usuario fue desactivado o el token expiro (sesion inactiva),
        // la sesion no debe restaurarse: se limpia y vuelve al login.
        await ApiClient.me();
        _sesion = SesionActual(
          accessToken: json['access_token'],
          usuarioId: json['usuario_id'],
          nombre: json['nombre'],
          tipoUsuario: json['tipo_usuario'],
        );
      } catch (_) {
        await ApiClient.limpiarToken();
        await prefs.remove(_sesionKey);
      }
    }
    _cargando = false;
    notifyListeners();
  }

  Future<void> _guardarSesionEnDisco(SesionActual sesion) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sesionKey,
      jsonEncode({
        'access_token': sesion.accessToken,
        'usuario_id': sesion.usuarioId,
        'nombre': sesion.nombre,
        'tipo_usuario': sesion.tipoUsuario,
      }),
    );
  }

  Future<void> registrar({
    required String email,
    required String password,
    required String nombre,
    required String tipoUsuario,
  }) async {
    final sesion = await AuthService.registrar(
      email: email,
      password: password,
      nombre: nombre,
      tipoUsuario: tipoUsuario,
    );
    await ApiClient.guardarToken(sesion.accessToken);
    await _guardarSesionEnDisco(sesion);
    _sesion = sesion;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    final sesion = await AuthService.login(email: email, password: password);
    await ApiClient.guardarToken(sesion.accessToken);
    await _guardarSesionEnDisco(sesion);
    _sesion = sesion;
    notifyListeners();
  }

  Future<void> cerrarSesion() async {
    await ApiClient.limpiarToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sesionKey);
    _sesion = null;
    notifyListeners();
  }
}
