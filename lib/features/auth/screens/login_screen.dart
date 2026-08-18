import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/google_auth_service.dart';
import '../../conductor/screens/registro_conductor_multipaso.dart';
import 'reset_password_screen.dart';
import 'seleccion_tipo_cuenta_screen.dart';

/// Login principal de HablaVas: fondo oscuro, logo grande y llamativo.
/// Solo email + contraseña (el perfil se detecta por el correo al iniciar
/// sesion). El boton "Registrarme" lleva al formulario multipaso del conductor.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultarPassword = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().login(email: _email.text.trim(), password: _password.text);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Login o registro con Google. Primero intenta sin tipoUsuario (caso mas
  /// comun: cuenta ya existe). Si el backend dice que es cuenta nueva y falta
  /// el tipo, se le pregunta al usuario (Conductor o Pasajero) y reintenta.
  Future<void> _entrarConGoogle() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final idToken = await GoogleAuthService.obtenerIdToken();
      if (idToken == null) return; // usuario cerro el selector de Google
      await _intentarLoginGoogle(idToken);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _intentarLoginGoogle(String idToken, {String? tipoUsuario, bool nuevoConductor = false}) async {
    try {
      await context.read<AuthProvider>().loginConGoogle(idToken: idToken, tipoUsuario: tipoUsuario);
      // Conductor NUEVO por Google: tras el login va directo al formulario
      // de 5 pasos con sus datos pre-llenados para completar los documentos.
      // Se usa push (NO pushReplacement): el multipaso va ENCIMA del Home para
      // que al terminar popUntil(isFirst) regrese al Home (validación).
      if (nuevoConductor) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const RegistroConductorMultipaso(google: true)),
        );
      }
    } on ApiException catch (e) {
      // Cuenta nueva: el backend pide tipoUsuario. Le preguntamos al usuario
      // y reintentamos una sola vez con lo que elija.
      if (e.errorCode == 'VALIDATION_ERROR' && tipoUsuario == null && mounted) {
        final elegido = await _preguntarTipoCuenta();
        if (elegido != null) {
          await _intentarLoginGoogle(idToken, tipoUsuario: elegido, nuevoConductor: elegido == 'conductor');
        }
        return;
      }
      rethrow;
    }
  }

  Future<String?> _preguntarTipoCuenta() {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Qué tipo de cuenta quieres crear?'),
        content: const Text('Es la primera vez que entras con esta cuenta de Google.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('conductor'),
            child: const Text('Conductor'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('cliente'),
            child: const Text('Pasajero'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 448),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo grande y llamativo
                Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: AppColors.yellow.withOpacity(0.35), blurRadius: 40, spreadRadius: 6),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'logo_icons/logo.webp',
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'HablaVas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 46,
                    fontWeight: FontWeight.w900,
                    color: AppColors.yellow,
                    shadows: [
                      Shadow(color: AppColors.black, offset: Offset(2, 2), blurRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ingresa a tu cuenta',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 17, color: Colors.white70),
                ),
                const SizedBox(height: 24),
                // Card blanca con los campos
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _campo(_email, 'Usuario o correo', Icons.person),
                      const SizedBox(height: 12),
                      _campo(
                        _password,
                        'Contraseña',
                        Icons.lock,
                        oculto: _ocultarPassword,
                        sufijo: IconButton(
                          icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off, color: AppColors.textDim),
                          onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 12.5),
                        ),
                      ],
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.yellow,
                            foregroundColor: AppColors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _cargando ? null : _enviar,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_cargando ? 'Espera...' : 'Ingresar'),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
                        ),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.yellow),
                        ),
                      ),
                      const Divider(height: 20),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.black,
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _cargando ? null : _entrarConGoogle,
                          icon: Image.asset(
                            'assets/icons/g-logo.png',
                            width: 24,
                            height: 24,
                            errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 26),
                          ),
                          label: const Text('Continuar con Google', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.black,
                            side: const BorderSide(color: AppColors.line),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SeleccionTipoCuentaScreen()),
                          ),
                          child: const Text('Registrarme', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icono, {bool oculto = false, Widget? sufijo}) {
    return TextField(
      controller: c,
      obscureText: oculto,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icono, color: AppColors.textDim),
        suffixIcon: sufijo,
      ),
    );
  }
}
