import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';

/// Componente COMPARTIDO para subir/previsualizar un documento del conductor.
/// - Conductor: al tocar abre la galeria y sube la foto (preview en miniatura).
/// - Admin: recibe solo url para revisar (modo soloLectura).
/// Devuelve via [alSubir] los bytes+nombre para que el llamador haga la subida.
class TarjetaSubidaDocumento extends StatefulWidget {
  final String etiqueta;
  final IconData icono;
  final String? urlPreview;
  final bool soloLectura;
  final Future<void> Function(Uint8List bytes, String nombreArchivo)? alSubir;
  final VoidCallback? alTocarPreview;

  const TarjetaSubidaDocumento({
    super.key,
    required this.etiqueta,
    required this.icono,
    this.urlPreview,
    this.soloLectura = false,
    this.alSubir,
    this.alTocarPreview,
  });

  @override
  State<TarjetaSubidaDocumento> createState() => _TarjetaSubidaDocumentoState();
}

class _TarjetaSubidaDocumentoState extends State<TarjetaSubidaDocumento> {
  bool _subiendo = false;
  Uint8List? _previewLocal;

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
    if (imagen == null || !mounted) return;

    final bytes = await imagen.readAsBytes();
    final nombre = imagen.name.isNotEmpty ? imagen.name : 'documento.jpg';

    setState(() {
      _subiendo = true;
      _previewLocal = bytes;
    });
    try {
      await widget.alSubir?.call(bytes, nombre);
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  bool get _tieneFoto => _previewLocal != null || widget.urlPreview != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.soloLectura ? widget.alTocarPreview : (_subiendo ? null : _elegirFoto),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _tieneFoto ? AppColors.green : AppColors.line, width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 110,
                width: double.infinity,
                child: _previewLocal != null
                    ? Image.memory(_previewLocal!, fit: BoxFit.cover)
                    : widget.urlPreview != null
                        ? Image.network(widget.urlPreview!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholderArea())
                        : _placeholderArea(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(_tieneFoto ? Icons.check_circle : widget.icono,
                      size: 20, color: _tieneFoto ? AppColors.green : AppColors.yellow),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.etiqueta,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: _tieneFoto ? AppColors.green : AppColors.black,
                      ),
                    ),
                  ),
                  if (_subiendo)
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow))
                  else if (!widget.soloLectura)
                    Icon(_tieneFoto ? Icons.camera_alt : Icons.add_a_photo,
                        size: 18, color: _tieneFoto ? AppColors.green : AppColors.black)
                  else
                    const Icon(Icons.open_in_full, size: 16, color: AppColors.textDim),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderArea() {
    return Container(
      color: AppColors.gray,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(widget.icono, size: 36, color: AppColors.line),
          const SizedBox(height: 6),
          Text(
            widget.soloLectura ? 'Sin foto' : 'Toca para subir',
            style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
