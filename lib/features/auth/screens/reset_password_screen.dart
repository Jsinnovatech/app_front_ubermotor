import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/auth_service.dart';

/// Recuperar contraseña (mismo patron que Comanda): paso 1 envia un codigo
/// de 6 digitos por email, paso 2 confirma el codigo y la nueva contraseña.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _email = TextEditingController();
  final _codigo = TextEditingController();
  final _nuevaPassword = TextEditingController();
  bool _pasoEnviado = false;
  bool _cargando = false;
  String? _error;
  String? _mensaje;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _nuevaPassword.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    setState(() {
      _cargando = true;
      _error = null;
      _mensaje = null;
    });
    try {
      final msg = await AuthService.solicitarReset(email: _email.text.trim());
      setState(() {
        _pasoEnviado = true;
        _mensaje = msg;
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _resetear() async {
    setState(() {
      _cargando = true;
      _error = null;
      _mensaje = null;
    });
    try {
      final msg = await AuthService.resetearPassword(
        email: _email.text.trim(),
        codigo: _codigo.text.trim(),
        nuevaPassword: _nuevaPassword.text,
      );
      setState(() => _mensaje = msg);
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
        backgroundColor: AppColors.gray,
        elevation: 0,
        title: const Text('Recuperar contraseña', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
      ),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.lock_reset, size: 48, color: AppColors.yellow),
                const SizedBox(height: 8),
                const Text(
                  'Restablece tu contraseña',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
                const SizedBox(height: 12),
                if (!_pasoEnviado) ...[
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email, color: AppColors.textDim),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Te enviaremos un código de 6 dígitos a tu correo.',
                    style: TextStyle(fontSize: 12, color: AppColors.textDim),
                  ),
                ] else ...[
                  TextField(
                    controller: _codigo,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: 'Código de 6 dígitos',
                      prefixIcon: Icon(Icons.pin, color: AppColors.textDim),
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nuevaPassword,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Nueva contraseña (mínimo 8)',
                      prefixIcon: Icon(Icons.lock, color: AppColors.textDim),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_mensaje != null)
                    Text(_mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _cargando
                        ? null
                        : () {
                            if (_pasoEnviado) {
                              _resetear();
                            } else {
                              _enviarCodigo();
                            }
                          },
                    child: Text(
                      _cargando ? 'Espera...' : (_pasoEnviado ? 'Cambiar contraseña' : 'Enviar código'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Volver al login', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
