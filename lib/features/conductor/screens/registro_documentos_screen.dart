import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/conductor_service.dart';

/// Registro/onboarding del conductor: sube TODOS sus documentos antes de que
/// el admin lo valide. La cuenta queda "en validacion" hasta ser aprobada.
class RegistroDocumentosScreen extends StatefulWidget {
  const RegistroDocumentosScreen({super.key});

  @override
  State<RegistroDocumentosScreen> createState() => _RegistroDocumentosScreenState();
}

class _RegistroDocumentosScreenState extends State<RegistroDocumentosScreen> {
  bool _subiendo = false;
  String? _mensaje;

  // (tipo, cara, etiqueta, icono)
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

  Future<void> _subirDocumento(String tipo, String? cara, String label) async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (imagen == null || !mounted) return;

    setState(() {
      _subiendo = true;
      _mensaje = null;
    });
    try {
      final bytes = await imagen.readAsBytes();
      final nombre = imagen.name.isNotEmpty ? imagen.name : '$tipo.jpg';
      await ConductorService.subirDocumento(
        tipo: tipo,
        cara: cara,
        bytes: bytes,
        nombreArchivo: nombre,
      );
      if (!mounted) return;
      setState(() => _mensaje = '$label subido. El admin lo validará.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _mensaje = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _subiendo = false);
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
          'Completa tu registro',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppColors.yellow),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.black,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sube tus documentos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.yellow),
                ),
                SizedBox(height: 6),
                Text(
                  'Necesitamos verificar tu identidad, tu brevete, el SOAT y tu moto. '
                  'Un administrador revisará todo antes de que puedas operar.',
                  style: TextStyle(fontSize: 13, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._documentos.map((doc) {
            final (tipo, cara, label, icono) = doc;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.line),
                ),
                tileColor: AppColors.white,
                leading: Icon(icono, color: AppColors.yellow, size: 26),
                title: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
                trailing: _subiendo
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow),
                      )
                    : const Icon(Icons.add_a_photo, color: AppColors.black),
                onTap: _subiendo ? null : () => _subirDocumento(tipo, cara, label),
              ),
            );
          }),
          const SizedBox(height: 12),
          if (_mensaje != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.yellowSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _mensaje!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.black),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => context.read<AuthProvider>().cerrarSesion(),
              child: const Text('TERMINAR — Esperar validación', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}
