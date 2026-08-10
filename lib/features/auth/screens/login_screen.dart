import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';

/// Login y registro unico para los tres perfiles. El usuario elige el perfil
/// en el registro; en el login el email ya identifica a la persona.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _esRegistro = false;
  String _tipoSeleccionado = 'conductor';
  final _nombre = TextEditingController();
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
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              const Icon(Icons.two_wheeler, size: 64, color: AppColors.yellow),
              const SizedBox(height: 8),
              const Text(
                'UberMotor',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              const SizedBox(height: 4),
              Text(
                _esRegistro ? 'Crea tu cuenta' : 'Ingresa con tu perfil',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textDim),
              ),
              const SizedBox(height: 24),
              if (_esRegistro) ...[
                _campo(_nombre, 'Nombre', Icons.person),
                const SizedBox(height: 12),
                const Text('Perfil', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.black)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _chipPerfil('conductor', '🛵 Conductor'),
                    _chipPerfil('cliente', '🙋 Cliente'),
                    _chipPerfil('administrador', '🛠️ Admin'),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              _campo(_email, 'Email', Icons.email),
              const SizedBox(height: 12),
              _campo(_password, 'Contraseña', Icons.lock, oculto: true),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700, fontSize: 12.5)),
              ],
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _cargando ? null : _enviar,
                child: Text(_cargando ? 'Espera...' : (_esRegistro ? 'Registrarme' : 'Ingresar')),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _esRegistro = !_esRegistro;
                  _error = null;
                }),
                child: Text(
                  _esRegistro ? 'Ya tengo cuenta — Ingresar' : 'No tengo cuenta — Registrarme',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icono, {bool oculto = false}) {
    return TextField(
      controller: c,
      obscureText: oculto,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icono, color: AppColors.textDim)),
    );
  }

  Widget _chipPerfil(String tipo, String etiqueta) {
    final seleccionado = _tipoSeleccionado == tipo;
    return ChoiceChip(
      label: Text(etiqueta, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
      selected: seleccionado,
      selectedColor: AppColors.yellow,
      backgroundColor: AppColors.gray,
      labelStyle: TextStyle(color: seleccionado ? AppColors.black : AppColors.black),
      onSelected: (_) => setState(() => _tipoSeleccionado = tipo),
    );
  }
}
