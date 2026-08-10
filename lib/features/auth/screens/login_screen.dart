import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

/// Login replicado 1:1 del diseno de Stitch (MotoRide): card blanca con
/// borde, segmented control de rol (Driver/Client/Admin), inputs con iconos,
/// boton amarillo de 56px. Solo queda loguear con email+password; el perfil
/// se elige en el segmented control para el registro.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _nombre = TextEditingController();
  bool _esRegistro = false;
  String _tipoSeleccionado = 'conductor';
  bool _ocultarPassword = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      if (_esRegistro) {
        await auth.registrar(
          email: _email.text.trim(),
          password: _password.text,
          nombre: _nombre.text.trim(),
          tipoUsuario: _tipoSeleccionado,
        );
      } else {
        await auth.login(email: _email.text.trim(), password: _password.text);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 448),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD4C5AC), width: 1),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.two_wheeler, size: 60, color: AppColors.yellow),
                const SizedBox(height: 8),
                const Text(
                  'HablaVas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
                Text(
                  _esRegistro ? 'Crea tu cuenta' : 'Ingresa a tu cuenta',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Color(0xFF4F4632)),
                ),
                const SizedBox(height: 24),
                _segmentedRoles(),
                const SizedBox(height: 12),
                if (_esRegistro) ...[
                  _campo(_nombre, 'Nombre', Icons.person),
                  const SizedBox(height: 12),
                ],
                _campo(_email, 'Email o teléfono', Icons.person),
                const SizedBox(height: 12),
                _campo(_password, 'Contraseña', Icons.lock, oculto: _ocultarPassword, sufijo: _botonOjo()),
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
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _cargando ? null : _enviar,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_cargando ? 'Espera...' : (_esRegistro ? 'Registrarme' : 'Ingresar')),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _esRegistro = !_esRegistro;
                    _error = null;
                  }),
                  child: Text(
                    _esRegistro ? 'Ya tengo cuenta — Ingresar' : 'No tengo cuenta — Registrarme',
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Segmented control estilo Stitch: roles disponibles.
  Widget _segmentedRoles() {
    final opciones = [
      ('conductor', 'Conductor'),
      ('cliente', 'Cliente'),
      ('administrador', 'Admin'),
      ('policia', 'Policía'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4C5AC)),
      ),
      child: Row(
        children: opciones.map((opcion) {
          final (tipo, etiqueta) = opcion;
          final seleccionado = _tipoSeleccionado == tipo;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tipoSeleccionado = tipo),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: seleccionado ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: seleccionado
                      ? const [BoxShadow(color: Colors.black12, blurRadius: 2)]
                      : null,
                ),
                child: Text(
                  etiqueta,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: seleccionado ? FontWeight.w800 : FontWeight.w600,
                    color: seleccionado ? AppColors.black : AppColors.textDim,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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

  Widget _botonOjo() {
    return IconButton(
      icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off, color: AppColors.textDim),
      onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
    );
  }
}
