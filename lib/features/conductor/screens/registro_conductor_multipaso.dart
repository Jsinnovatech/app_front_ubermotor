import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/conductor_service.dart';
import '../widgets/tarjeta_subida_documento.dart';

/// Registro del conductor en TABS rectangulares (formulario epico):
/// Tab 1: Datos personales (nombre, email, contraseña, repetir contraseña).
/// Tab 2: Documentos (DNI 2 caras, brevete 2 caras, SOAT, 3 fotos moto).
/// Tras completar, vuelve al login y queda pendiente de validacion del admin.
class RegistroConductorMultipaso extends StatefulWidget {
  const RegistroConductorMultipaso({super.key});

  @override
  State<RegistroConductorMultipaso> createState() => _RegistroConductorMultipasoState();
}

class _RegistroConductorMultipasoState extends State<RegistroConductorMultipaso> {
  int _paso = 0;
  bool _cargando = false;
  bool _cuentaCreada = false;
  String? _error;

  // Tab 1: datos
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _ocultarPassword = true;
  bool _ocultarPassword2 = true;

  // Tab 2: documentos subidos (tipo|cara -> marca de completado)
  final Set<String> _subidos = {};

  static const _documentos = [
    ('dni', 'frente', 'DNI — Frente', Icons.badge),
    ('dni', 'dorso', 'DNI — Dorso', Icons.badge_outlined),
    ('brevete', 'frente', 'Brevete — Frente', Icons.card_membership),
    ('brevete', 'dorso', 'Brevete — Dorso', Icons.card_membership_outlined),
    ('soat', null, 'SOAT', Icons.verified_user),
    ('moto', null, 'Foto Moto 1', Icons.two_wheeler),
    ('moto', null, 'Foto Moto 2', Icons.two_wheeler_outlined),
    ('moto', null, 'Foto Moto 3', Icons.two_wheeler),
  ];

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
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
            tipoUsuario: 'conductor',
          );
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _cuentaCreada = true;
        _paso = 1;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', '');
      });
    }
  }

  /// Al terminar: vuelve al login (la cuenta quedo pendiente de validacion).
  void _terminar() {
    context.read<AuthProvider>().cerrarSesion();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.yellow),
          onPressed: _paso > 0
              ? () => setState(() => _paso = 0)
              : () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Registro de Conductor',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Tabs rectangulares: Datos | Documentos
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(child: _tab(0, '1. Datos', Icons.person_outline)),
                const SizedBox(width: 8),
                Expanded(child: _tab(1, '2. Documentos', Icons.badge_outlined)),
              ],
            ),
          ),
          Expanded(
            child: _paso == 0 ? _tabDatos() : _tabDocumentos(),
          ),
        ],
      ),
    );
  }

  Widget _tab(int indice, String etiqueta, IconData icono) {
    final activo = _paso == indice;
    return GestureDetector(
      onTap: () {
        if (indice == 1 && !_cuentaCreada) {
          setState(() => _error = 'Primero crea tu cuenta en el paso 1');
          return;
        }
        setState(() => _paso = indice);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: activo ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activo ? AppColors.black : AppColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 20, color: activo ? AppColors.yellow : AppColors.textDim),
            const SizedBox(width: 6),
            Text(
              etiqueta,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: activo ? AppColors.yellow : AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabDatos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
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
            'Bienvenido a HablaVas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.black),
          ),
          const SizedBox(height: 4),
          const Text(
            'Regístrate como conductor y empieza a ganar.',
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
              onPressed: _cargando ? null : _crearCuenta,
              child: Text(
                _cargando ? 'Creando cuenta...' : 'CONTINUAR → DOCUMENTOS',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabDocumentos() {
    // 2 columnas de tarjetas con preview
    final tarjetas = <Widget>[
      for (final (tipo, cara, label, icono) in _documentos)
        TarjetaSubidaDocumento(
          etiqueta: label,
          icono: icono,
          alSubir: (bytes, nombre) async {
            await ConductorService.subirDocumento(tipo: tipo, cara: cara, bytes: bytes, nombreArchivo: nombre);
            if (mounted) setState(() => _subidos.add(label));
          },
        ),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
          child: const Text(
            'Sube cada documento tocando su tarjeta. Un administrador lo revisará y te aprobará.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
          ),
        ),
        const SizedBox(height: 16),
        // Grid 2 columnas de tarjetas con preview
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.78,
          children: tarjetas,
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _terminar,
            icon: const Icon(Icons.check),
            label: const Text('TERMINAR — Volver al login', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
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
