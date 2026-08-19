import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Resultado del dialogo de calificacion: estrellas (1-5) + comentario opcional.
class ResultadoCalificacion {
  final int puntaje;
  final String? comentario;

  ResultadoCalificacion(this.puntaje, this.comentario);
}

/// Dialogo de calificacion mutua (cliente -> conductor, o al reves) con
/// estrellas y comentario opcional. Devuelve null si cancela.
Future<ResultadoCalificacion?> mostrarDialogoCalificacion(
  BuildContext context, {
  String titulo = 'Califica el viaje',
}) {
  return showDialog<ResultadoCalificacion>(
    context: context,
    builder: (_) => _DialogoCalificacion(titulo: titulo),
  );
}

class _DialogoCalificacion extends StatefulWidget {
  final String titulo;

  const _DialogoCalificacion({required this.titulo});

  @override
  State<_DialogoCalificacion> createState() => _DialogoCalificacionState();
}

class _DialogoCalificacionState extends State<_DialogoCalificacion> {
  int _puntaje = 0;
  final _comentario = TextEditingController();

  @override
  void dispose() {
    _comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(widget.titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('¿Cómo estuvo el viaje? Toca las estrellas.'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final lleno = i < _puntaje;
              return IconButton(
                iconSize: 34,
                icon: Icon(lleno ? Icons.star : Icons.star_border, color: AppColors.yellow),
                onPressed: () => setState(() => _puntaje = i + 1),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _comentario,
            maxLength: 300,
            decoration: const InputDecoration(
              hintText: 'Comentario (opcional)',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.yellow,
            foregroundColor: AppColors.black,
          ),
          onPressed: _puntaje == 0
              ? null
              : () {
                  final comentario = _comentario.text.trim();
                  Navigator.of(context).pop(
                    ResultadoCalificacion(_puntaje, comentario.isEmpty ? null : comentario),
                  );
                },
          child: const Text('Enviar', style: TextStyle(fontWeight: FontWeight.w900)),
        ),
      ],
    );
  }
}
