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

  /// Login/registro con Google. tipoUsuario solo hace falta si es cuenta
  /// nueva (el backend responde error de validacion si falta y no existe
  /// el email todavia); en login normal se puede omitir.
  static Future<SesionActual> loginGoogle({
    required String idToken,
    String? tipoUsuario,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.loginGoogle,
      conAuth: false,
      body: {
        'id_token': idToken,
        if (tipoUsuario != null) 'tipo_usuario': tipoUsuario,
      },
    );
    return _sesionDesdeLogin(data);
  }

  static Future<String> solicitarReset({required String email}) async {
    final data = await ApiClient.post(
      '${ApiConfig.baseUrl}/auth/solicitar-reset',
      conAuth: false,
      body: {'email': email},
    );
    return data['message'] as String;
  }

  static Future<String> resetearPassword({
    required String email,
    required String codigo,
    required String nuevaPassword,
  }) async {
    final data = await ApiClient.post(
      '${ApiConfig.baseUrl}/auth/resetear-password',
      conAuth: false,
      body: {'email': email, 'codigo': codigo, 'nueva_password': nuevaPassword},
    );
    return data['message'] as String;
  }
}
