import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

/// Registro simple del Pasajero (cliente): nombre, correo, contraseña.
/// A diferencia del conductor, no necesita subir documentos.
class RegistroClienteScreen extends StatefulWidget {
  const RegistroClienteScreen({super.key});

  @override
  State<RegistroClienteScreen> createState() => _RegistroClienteScreenState();
}

class _RegistroClienteScreenState extends State<RegistroClienteScreen> {
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _ocultarPassword = true;
  bool _ocultarPassword2 = true;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (_password.text.length < 8) {
      setState(() => _error = 'La contraseña debe tener mínimo 8 caracteres');
      return;
    }
    if (_password.text != _password2.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().registrar(
            email: _email.text.trim(),
            password: _password.text,
            nombre: _nombre.text.trim(),
            tipoUsuario: 'cliente',
          );
      // Al registrarse queda logueado directo.
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
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: const Text(
          'Registro de Pasajero',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset('logo_icons/logo.webp', width: 100, height: 100, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Crea tu cuenta de Pasajero',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pide motos y muévete por la ciudad.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textDim),
            ),
            const SizedBox(height: 24),
            _campo(_nombre, 'Nombre completo', Icons.person),
            const SizedBox(height: 14),
            _campo(_email, 'Correo electrónico', Icons.email),
            const SizedBox(height: 14),
            _campo(
              _password,
              'Contraseña (mín. 8 caracteres)',
              Icons.lock,
              oculto: _ocultarPassword,
              sufijo: IconButton(
                icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off, color: AppColors.textDim),
                onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
              ),
            ),
            const SizedBox(height: 14),
            _campo(
              _password2,
              'Repetir contraseña',
              Icons.lock_outline,
              oculto: _ocultarPassword2,
              sufijo: IconButton(
                icon: Icon(_ocultarPassword2 ? Icons.visibility : Icons.visibility_off, color: AppColors.textDim),
                onPressed: () => setState(() => _ocultarPassword2 = !_ocultarPassword2),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _cargando ? null : _registrar,
                child: Text(
                  _cargando ? 'Creando cuenta...' : 'REGISTRARME',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icono, {bool oculto = false, Widget? sufijo}) {
    return TextField(
      controller: c,
      obscureText: oculto,
      style: const TextStyle(color: AppColors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icono, color: AppColors.textDim),
        suffixIcon: sufijo,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
