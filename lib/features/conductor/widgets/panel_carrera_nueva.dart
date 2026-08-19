import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';
import 'campo_oferta.dart';

/// Panel accionable estilo InDrive para una carrera nueva que llega por
/// WebSocket: el conductor escribe SU oferta sobre la tarifa del cliente.
/// Reemplaza el Aceptar directo: ofertar no consume saldo (se consume cuando
/// el cliente acepta la oferta).
class PanelCarreraNueva extends StatefulWidget {
  final Viaje viaje;
  final Future<void> Function(double) onOfertar;
  final VoidCallback onRechazar;
  final Duration plazoReaccion;

  const PanelCarreraNueva({
    super.key,
    required this.viaje,
    required this.onOfertar,
    required this.onRechazar,
    this.plazoReaccion = const Duration(seconds: 50),
  });

  @override
  State<PanelCarreraNueva> createState() => _PanelCarreraNuevaState();
}

class _PanelCarreraNuevaState extends State<PanelCarreraNueva> {
  Timer? _timer;
  late int _segundosRestantes;
  bool _ofertando = false;
  double _precio = 3.0;

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
                        'Piso S/ ${v.tarifa.toStringAsFixed(2)} · ${v.metodoPagoCliente}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.yellow),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Campo de oferta del conductor (min S/ 3.00, max S/ 50.00)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tu oferta',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.white),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CampoOferta(onCambio: (v) => _precio = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                          onPressed: _ofertando
                              ? null
                              : () async {
                                  setState(() => _ofertando = true);
                                  await widget.onOfertar(_precio);
                                },
                          child: Text(
                            _ofertando ? 'Enviando...' : 'Ofertar S/ ${_precio.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
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