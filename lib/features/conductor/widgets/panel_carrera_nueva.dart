import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';

/// Panel accionable estilo InDrive para una carrera nueva que llega por
/// WebSocket. Reemplaza el SnackBar informativo: muestra origen/destino,
/// rider (nombre + rating) y botones Aceptar / Rechazar.
class PanelCarreraNueva extends StatefulWidget {
  final Viaje viaje;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;
  final Duration plazoReaccion;

  const PanelCarreraNueva({
    super.key,
    required this.viaje,
    required this.onAceptar,
    required this.onRechazar,
    this.plazoReaccion = const Duration(seconds: 15),
  });

  @override
  State<PanelCarreraNueva> createState() => _PanelCarreraNuevaState();
}

class _PanelCarreraNuevaState extends State<PanelCarreraNueva> {
  Timer? _timer;
  late int _segundosRestantes;

  @override
  void initState() {
    super.initState();
    _segundosRestantes = widget.plazoReaccion.inSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_segundosRestantes <= 1) {
        _timer?.cancel();
        widget.onRechazar();
        return;
      }
      setState(() => _segundosRestantes--);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.viaje;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.black,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active, color: AppColors.black, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Nueva carrera',
                    style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.black, fontSize: 15),
                  ),
                  const Spacer(),
                  Text(
                    '${_segundosRestantes}s',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.black, fontSize: 14),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fila(Icons.place, v.origenDireccion ?? 'Origen'),
                  const SizedBox(height: 4),
                  _fila(Icons.sports_motorsports, v.destinoDireccion ?? 'Destino'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.yellow, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${v.riderNombre ?? 'Cliente'} · ⭐ ${v.riderRating?.toStringAsFixed(1) ?? '—'}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        'S/ ${v.tarifa.toStringAsFixed(2)} · ${v.metodoPagoCliente}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.yellow),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                            side: const BorderSide(color: AppColors.red),
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: widget.onRechazar,
                          child: const Text('Rechazar', style: TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green,
                            foregroundColor: AppColors.white,
                            minimumSize: const Size.fromHeight(44),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: widget.onAceptar,
                          child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w900)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fila(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, color: AppColors.yellow, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.white),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
