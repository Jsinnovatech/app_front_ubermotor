import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/conductor_provider.dart';
import '../../../services/conductor_service.dart';

/// Perfil/onboarding del conductor: datos, moto y subida de documentos
/// (foto, DNI, licencia, antecedentes) que el admin aprueba.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _subiendo = false;
  String? _mensaje;
  List<Map<String, dynamic>> _documentos = [];

  @override
  void initState() {
    super.initState();
    context.read<ConductorProvider>().cargarPerfil();
    _cargarDocumentos();
  }

  /// Carga los documentos reales (tabla documentos_conductores).
  Future<void> _cargarDocumentos() async {
    try {
      final docs = await ConductorService.documentos();
      if (mounted) setState(() => _documentos = docs);
    } catch (_) {}
  }

  /// URL del primer documento del tipo dado (o null si no lo subio).
  String? _urlDocumento(String tipo) {
    for (final d in _documentos) {
      if (d['tipo'] == tipo && d['url'] != null) return d['url'] as String;
    }
    return null;
  }

  Future<void> _subirDocumento(String tipo, String label) async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (imagen == null) return;

    setState(() {
      _subiendo = true;
      _mensaje = null;
    });
    try {
      final bytes = await imagen.readAsBytes();
      final nombre = imagen.name.isNotEmpty ? imagen.name : '$tipo.jpg';
      await ConductorService.subirDocumento(tipo: tipo, bytes: bytes, nombreArchivo: nombre);
      await context.read<ConductorProvider>().cargarPerfil();
      setState(() => _mensaje = '$label subido correctamente');
    } catch (e) {
      setState(() => _mensaje = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final conductor = context.watch<ConductorProvider>().perfil;

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.gray,
        elevation: 0,
        title: const Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.yellow,
              backgroundImage: conductor?.fotoUrl != null ? NetworkImage(conductor!.fotoUrl!) : null,
              child: conductor?.fotoUrl == null
                  ? const Icon(Icons.two_wheeler, size: 40, color: AppColors.black)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              auth.sesion?.nombre ?? conductor?.nombre ?? 'Conductor',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              auth.sesion?.tipoUsuario ?? '',
              style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line, width: 1),
            ),
            child: Row(
              children: [
                _dato('Rating', conductor?.ratingPromedio.toStringAsFixed(1) ?? '5.0', AppColors.yellow),
                Container(width: 1, height: 40, color: AppColors.line),
                _dato('Viajes', '${conductor?.viajesCompletados ?? 0}', AppColors.blue),
                Container(width: 1, height: 40, color: AppColors.line),
                _dato('Saldo', '${conductor?.saldoCarreras ?? 0}', AppColors.green),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'DOCUMENTOS PARA OPERAR',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 4),
          const Text(
            'El administrador aprueba tu perfil cuando revise estos documentos.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textDim),
          ),
          const SizedBox(height: 12),
          _filaDocumento('Tu foto', _urlDocumento('foto'), Icons.person, 'foto'),
          _filaDocumento('DNI', _urlDocumento('dni'), Icons.badge, 'dni'),
          _filaDocumento('Brevete', _urlDocumento('brevete'), Icons.drive_eta, 'brevete'),
          _filaDocumento('SOAT', _urlDocumento('soat'), Icons.verified_user, 'soat'),
          _filaDocumento('Moto', _urlDocumento('moto'), Icons.two_wheeler, 'moto'),
          if (_mensaje != null) ...[
            const SizedBox(height: 12),
            Text(_mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 24),
          if (conductor?.aprobado == false)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.pending, color: AppColors.black),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Pendiente de aprobación del administrador.',
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.red,
                side: const BorderSide(color: AppColors.red, width: 1.5),
              ),
              onPressed: () => context.read<AuthProvider>().cerrarSesion(),
              icon: const Icon(Icons.logout),
              label: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaDocumento(String label, String? url, IconData icono, String tipo) {
    final subido = url != null;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: subido ? AppColors.green : AppColors.line, width: subido ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Icon(icono, color: subido ? AppColors.green : AppColors.textDim, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black)),
                Text(
                  subido ? 'Subido ✓' : 'No subido',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subido ? AppColors.green : AppColors.textDim),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _subiendo ? null : () => _subirDocumento(tipo, label),
            child: Text(subido ? 'Reemplazar' : 'Subir', style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _dato(String label, String valor, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(valor, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
