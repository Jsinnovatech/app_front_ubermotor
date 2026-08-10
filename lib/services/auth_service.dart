import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/sesion_model.dart';

/// Unico service que sabe de /auth/*. Registro y login unico para los
/// tres perfiles (conductor, cliente, administrador).
class AuthService {
  static Future<SesionActual> registrar({
    required String email,
    required String password,
    required String nombre,
    required String tipoUsuario,
    String? telefono,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.registro,
      conAuth: false,
      body: {
        'email': email,
        'password': password,
        'nombre': nombre,
        'tipo_usuario': tipoUsuario,
        if (telefono != null) 'telefono': telefono,
      },
    );
    return _sesionDesdeLogin(data);
  }

  static Future<SesionActual> login({required String email, required String password}) async {
    final data = await ApiClient.post(
      ApiConfig.login,
      conAuth: false,
      body: {'email': email, 'password': password},
    );
    return _sesionDesdeLogin(data);
  }

  static SesionActual _sesionDesdeLogin(Map<String, dynamic> data) {
    return SesionActual.desdeJson(data);
  }
}
