import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';
import '../../../services/calificacion_service.dart';

/// Pantalla post-viaje del conductor: califica al rider (1-5 estrellas).
/// Reemplaza el dialogo suelto por una pantalla dedicada, igual de simple.
class CalificarScreen extends StatefulWidget {
  final Viaje viaje;
  const CalificarScreen({super.key, required this.viaje});

  @override
  State<CalificarScreen> createState() => _CalificarScreenState();
}

class _CalificarScreenState extends State<CalificarScreen> {
  int _puntaje = 0;
  bool _enviando = false;
  bool _enviado = false;

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;
    return Scaffold(
      backgroundColor: AppColors.gray,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(Icons.star, size: 64, color: AppColors.yellow),
              const SizedBox(height: 16),
              const Text(
                '¿Cómo estuvo el viaje?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              const SizedBox(height: 8),
              Text(
                'Califica a ${v.riderNombre ?? 'tu rider'}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    iconSize: 44,
                    color: i < _puntaje ? AppColors.yellow : AppColors.line,
                    icon: Icon(i < _puntaje ? Icons.star : Icons.star_border),
                    onPressed: _enviado ? null : () => setState(() => _puntaje = i + 1),
                  );
                }),
              ),
              const Spacer(),
              if (_enviado)
                const Text(
                  '¡Gracias por tu calificación!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.green),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.black,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: (_puntaje == 0 || _enviando) ? null : _enviar,
                  child: Text(
                    _enviando ? 'Enviando...' : 'ENVIAR CALIFICACIÓN',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                child: const Text('VOLVER AL INICIO', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      await CalificacionService.calificar(viajeId: widget.viaje.id, puntaje: _puntaje);
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _enviado = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    }
  }
}
