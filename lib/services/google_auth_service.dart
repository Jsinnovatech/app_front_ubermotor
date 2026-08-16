import 'package:google_sign_in/google_sign_in.dart';

import '../core/config/api_config.dart';

/// Puente con el SDK nativo de Google Sign-In. Solo se encarga de abrir el
/// selector de cuentas y devolver el idToken; la sesion real (login/registro
/// contra el backend) la maneja AuthProvider, igual que con email+password.
class GoogleAuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // Con esto el idToken que devuelve Google trae "aud" = este client id,
    // que es lo que el backend valida (ver GOOGLE_CLIENT_ID en el backend).
    serverClientId: ApiConfig.googleClientId,
  );

  /// Abre el selector de cuentas de Google. Devuelve el idToken, o null si
  /// el usuario cancelo el selector.
  static Future<String?> obtenerIdToken() async {
    final cuenta = await _googleSignIn.signIn();
    if (cuenta == null) return null; // usuario cancelo
    final auth = await cuenta.authentication;
    return auth.idToken;
  }

  static Future<void> cerrarSesion() async {
    await _googleSignIn.signOut();
  }
}
