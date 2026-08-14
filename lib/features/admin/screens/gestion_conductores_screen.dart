import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/admin_service.dart';

/// Gestion de conductores del admin: ver lista, cargar foto de perfil y de
/// la moto, y aprobar/bloquear. El cliente recien ve al conductor aprobado.
class GestionConductoresScreen extends StatefulWidget {
  const GestionConductoresScreen({super.key});

  @override
  State<GestionConductoresScreen> createState() => _GestionConductoresScreenState();
}

class _GestionConductoresScreenState extends State<GestionConductoresScreen> {
  List<Map<String, dynamic>> _conductores = [];
  bool _cargando = true;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      _conductores = await AdminService.conductores();
    } catch (e) {
      _mensaje = e.toString();
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _cargarFoto(int conductorId, String nombre, String campo) async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (imagen == null) return;
    final bytes = await imagen.readAsBytes();
    try {
      await AdminService.cargarFoto(
        conductorId,
        campo: campo,
        bytes: bytes,
        nombre: imagen.name.isNotEmpty ? imagen.name : '$campo.jpg',
      );
      setState(() => _mensaje = '$nombre actualizado');
      await _cargar();
    } catch (e) {
      setState(() => _mensaje = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    }
  }

  Future<void> _aprobar(int conductorId, bool aprobado) async {
    try {
      await AdminService.aprobarConductor(conductorId, aprobado: aprobado);
      await _cargar();
    } catch (e) {
      setState(() => _mensaje = e.toString());
    }
  }

  /// Muestra todos los documentos del conductor en un modal para que el admin
  /// los revise antes de aprobarlo.
  Future<void> _verDocumentos(int conductorId) async {
    try {
      final docs = await AdminService.documentosConductor(conductorId);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Documentos del conductor', style: TextStyle(fontWeight: FontWeight.w900)),
          content: SizedBox(
            width: double.maxFinite,
            child: docs.isEmpty
                ? const Text('Sin documentos subidos.', textAlign: TextAlign.center)
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: docs.map((d) {
                      final tipo = d['tipo'] as String? ?? '';
                      final cara = d['cara'] as String?;
                      final url = d['url'] as String? ?? '';
                      final label = cara != null ? '${tipo.toUpperCase()} — $cara' : tipo.toUpperCase();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          onTap: () => showDialog<void>(
                            context: ctx,
                            builder: (_) => Dialog(
                              child: Image.network(url, fit: BoxFit.contain),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.photo, color: AppColors.yellow),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
                              ),
                              const Icon(Icons.open_in_full, size: 16, color: AppColors.textDim),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cerrar')),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _mensaje = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.gray,
        elevation: 0,
        title: const Text('Conductores', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
      ),
      body: RefreshIndicator(
        onRefresh: _cargar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_mensaje != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_mensaje!, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
              ),
            if (_cargando)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            else if (_conductores.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Sin conductores registrados.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textDim)),
              )
            else
              ..._conductores.map((c) => _tarjetaConductor(c)),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaConductor(Map<String, dynamic> c) {
    final id = c['id'] as int;
    final aprobado = c['aprobado'] == true;
    final tieneFoto = c['foto_url'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: aprobado ? AppColors.green : AppColors.redSoft, width: aprobado ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.yellowSoft,
                backgroundImage: tieneFoto ? NetworkImage(c['foto_url']!) : null,
                child: !tieneFoto ? const Icon(Icons.person, color: AppColors.black) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${c['nombre']} (#$id)', style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.black)),
                    Text(
                      aprobado ? 'Aprobado ✓' : 'Pendiente de aprobación',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: aprobado ? AppColors.green : AppColors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _botonAccion(
                icono: Icons.person,
                etiqueta: tieneFoto ? 'Foto ✓' : 'Foto',
                alTocar: () => _cargarFoto(id, 'Foto del conductor', 'foto'),
              ),
              _botonAccion(
                icono: Icons.two_wheeler,
                etiqueta: 'Foto moto',
                alTocar: () => _cargarFoto(id, 'Foto de la moto', 'moto'),
              ),
              _botonAccion(
                icono: Icons.folder_open,
                etiqueta: 'Documentos',
                alTocar: () => _verDocumentos(id),
              ),
              _botonAccion(
                icono: aprobado ? Icons.block : Icons.check_circle,
                etiqueta: aprobado ? 'Bloquear' : 'Aprobar',
                color: aprobado ? AppColors.red : AppColors.green,
                alTocar: () => _aprobar(id, !aprobado),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _botonAccion({
    required IconData icono,
    required String etiqueta,
    required VoidCallback alTocar,
    Color color = AppColors.yellow,
  }) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color, width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      onPressed: alTocar,
      icon: Icon(icono, size: 16),
      label: Text(etiqueta, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
    );
  }
}
