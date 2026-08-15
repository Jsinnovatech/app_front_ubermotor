import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/conductor_service.dart';

/// Registro del conductor en MULTIPASOS:
/// Paso 1: datos personales (nombre, email, contraseña).
/// Paso 2: subir documentos (DNI 2 caras, brevete 2 caras, SOAT, 3 fotos moto).
/// Tras completar, queda pendiente de validacion del admin.
class RegistroConductorMultipaso extends StatefulWidget {
  const RegistroConductorMultipaso({super.key});

  @override
  State<RegistroConductorMultipaso> createState() => _RegistroConductorMultipasoState();
}

class _RegistroConductorMultipasoState extends State<RegistroConductorMultipaso> {
  int _paso = 1;
  bool _cargando = false;
  String? _error;

  // Paso 1: datos
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _ocultarPassword = true;

  // Paso 2: documentos subidos (tipo|cara -> url? no, solo marcamos ok)
  final Set<String> _subidos = {};

  static const _documentos = [
    ('dni', 'frente', 'DNI — Frente', Icons.badge),
    ('dni', 'dorso', 'DNI — Dorso', Icons.badge_outlined),
    ('brevete', 'frente', 'Brevete — Frente', Icons.card_membership),
    ('brevete', 'dorso', 'Brevete — Dorso', Icons.card_membership_outlined),
    ('soat', null, 'SOAT', Icons.verified_user),
    ('moto', null, 'Foto de la Moto', Icons.two_wheeler),
    ('moto', null, 'Foto de la Moto (2)', Icons.two_wheeler_outlined),
    ('moto', null, 'Foto de la Moto (3)', Icons.two_wheeler),
  ];

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _crearCuenta() async {
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
        _paso = 2;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', '');
      });
    }
  }

  Future<void> _subirDocumento(String tipo, String? cara, String label) async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (imagen == null || !mounted) return;

    setState(() => _cargando = true);
    try {
      final bytes = await imagen.readAsBytes();
      final nombre = imagen.name.isNotEmpty ? imagen.name : '$tipo.jpg';
      await ConductorService.subirDocumento(tipo: tipo, cara: cara, bytes: bytes, nombreArchivo: nombre);
      if (!mounted) return;
      setState(() => _subidos.add(label));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.yellow),
          onPressed: _paso > 1
              ? () => setState(() => _paso = 1)
              : () => Navigator.of(context).pop(),
        ),
        title: Text(
          _paso == 1 ? 'Crea tu cuenta de Conductor' : 'Sube tus documentos',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 17),
        ),
      ),
      body: _paso == 1 ? _pasoDatos() : _pasoDocumentos(),
    );
  }

  Widget _pasoDatos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('logo_icons/logo.webp', width: 120, height: 120, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Bienvenido a HablaVas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.yellow),
          ),
          const SizedBox(height: 6),
          const Text(
            'Regístrate como conductor y empieza a ganar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          const SizedBox(height: 28),
          _campo(_nombre, 'Nombre completo', Icons.person, esOscuro: true),
          const SizedBox(height: 14),
          _campo(_email, 'Email', Icons.email, esOscuro: true),
          const SizedBox(height: 14),
          _campo(
            _password,
            'Contraseña (mín. 8 caracteres)',
            Icons.lock,
            esOscuro: true,
            oculto: _ocultarPassword,
            sufijo: IconButton(
              icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off, color: Colors.white54),
              onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _cargando ? null : _crearCuenta,
              child: Text(
                _cargando ? 'Creando cuenta...' : 'CONTINUAR → SUBIR DOCUMENTOS',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pasoDocumentos() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.yellow, borderRadius: BorderRadius.circular(12)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verificamos tu identidad',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              SizedBox(height: 4),
              Text(
                'Sube cada documento. Un administrador lo revisará y te aprobará.',
                style: TextStyle(fontSize: 12.5, color: AppColors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._documentos.map((doc) {
          final (tipo, cara, label, icono) = doc;
          final ok = _subidos.contains(label);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: ok ? AppColors.green : AppColors.line),
              ),
              tileColor: ok ? AppColors.greenSoft : AppColors.white,
              leading: Icon(ok ? Icons.check_circle : icono, color: ok ? AppColors.green : AppColors.yellow, size: 26),
              title: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: ok ? AppColors.green : AppColors.black)),
              trailing: _cargando
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow))
                  : Icon(ok ? Icons.done : Icons.add_a_photo, color: ok ? AppColors.green : AppColors.black),
              onTap: _cargando ? null : () => _subirDocumento(tipo, cara, label),
            ),
          );
        }),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
        ],
        const SizedBox(height: 16),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.yellow,
              foregroundColor: AppColors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
            icon: const Icon(Icons.check),
            label: const Text('TERMINAR — Esperar validación', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icono, {bool esOscuro = false, bool oculto = false, Widget? sufijo}) {
    return TextField(
      controller: c,
      obscureText: oculto,
      style: TextStyle(color: esOscuro ? Colors.white : AppColors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: esOscuro ? Colors.white54 : AppColors.textDim, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icono, color: esOscuro ? AppColors.yellow : AppColors.textDim),
        suffixIcon: sufijo,
        filled: esOscuro,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
