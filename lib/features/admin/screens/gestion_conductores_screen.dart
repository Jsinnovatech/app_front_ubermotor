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

  /// Muestra los documentos del conductor en CAROUSEL (una foto a la vez con
  /// flechas y contador) para que el admin los revise antes de aprobarlo.
  Future<void> _verDocumentos(int conductorId) async {
    try {
      final docs = await AdminService.documentosConductor(conductorId);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (ctx) => _CarruselDocumentos(docs: docs),
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

/// Carrusel de documentos del conductor: muestra las fotos una a la vez con
/// flechas de navegacion, contador y nombre de cada documento.
class _CarruselDocumentos extends StatefulWidget {
  final List<dynamic> docs;
  const _CarruselDocumentos({required this.docs});

  @override
  State<_CarruselDocumentos> createState() => _CarruselDocumentosState();
}

class _CarruselDocumentosState extends State<_CarruselDocumentos> {
  final PageController _controller = PageController();
  int _indice = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.docs.isEmpty) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.folder_open, size: 48, color: AppColors.yellow),
              const SizedBox(height: 12),
              const Text('Sin documentos subidos', style: TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 16),
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_open, color: AppColors.yellow),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Documentos del conductor',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Foto actual en grande (PageView = carrusel)
            SizedBox(
              height: 320,
              width: double.infinity,
              child: PageView.builder(
                controller: _controller,
                itemCount: widget.docs.length,
                onPageChanged: (i) => setState(() => _indice = i),
                itemBuilder: (_, i) {
                  final d = widget.docs[i];
                  final url = d['url'] as String? ?? '';
                  final tipo = d['tipo'] as String? ?? '';
                  final cara = d['cara'] as String?;
                  final label = cara != null ? '${tipo.toUpperCase()} — $cara' : tipo.toUpperCase();
                  return Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 60, color: AppColors.textDim),
                          ),
                        ),
                        Positioned(
                          bottom: 8,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                              child: Text(
                                label,
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            // Contador + flechas
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppColors.black, size: 28),
                  onPressed: _indice > 0
                      ? () => _controller.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
                      : null,
                ),
                Text(
                  '${_indice + 1} / ${widget.docs.length}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.black),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: AppColors.black, size: 28),
                  onPressed: _indice < widget.docs.length - 1
                      ? () => _controller.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeOut)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
