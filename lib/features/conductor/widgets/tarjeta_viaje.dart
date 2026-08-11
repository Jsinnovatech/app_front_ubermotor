import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/estado_chip.dart';
import '../../../models/viaje_model.dart';

/// Tarjeta de un viaje disponible: origen/destino, tarifa y botones
/// ACEPTAR (consume saldo) / RECHAZAR (cuenta para el -1 cada 3).
class TarjetaViaje extends StatelessWidget {
  final Viaje viaje;
  final VoidCallback onAceptar;
  final VoidCallback onRechazar;

  const TarjetaViaje({super.key, required this.viaje, required this.onAceptar, required this.onRechazar});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: AppColors.green, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    viaje.origenDireccion ?? 'Origen (${viaje.origenLat.toStringAsFixed(4)}, ${viaje.origenLng.toStringAsFixed(4)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.sports_motorsports, color: AppColors.blue, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    viaje.destinoDireccion ?? 'Destino (${viaje.destinoLat.toStringAsFixed(4)}, ${viaje.destinoLng.toStringAsFixed(4)})',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Rider: nombre + puntuacion
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.yellowSoft,
                    child: viaje.riderFotoUrl != null
                        ? ClipOval(
                            child: Image.network(
                              viaje.riderFotoUrl!,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 14, color: AppColors.black),
                            ),
                          )
                        : const Icon(Icons.person, size: 14, color: AppColors.black),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      viaje.riderNombre ?? 'Cliente',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.black),
                    ),
                  ),
                  const Icon(Icons.star, size: 14, color: AppColors.yellow),
                  const SizedBox(width: 3),
                  Text(
                    viaje.riderRating?.toStringAsFixed(1) ?? '—',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.black),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'S/ ${viaje.tarifa.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
                const Spacer(),
                EstadoChip(estado: viaje.estado, color: AppColors.azulEstado(viaje.estado)),
                const SizedBox(width: 8),
                Text(
                  viaje.metodoPagoCliente,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDim),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.white),
                    onPressed: onAceptar,
                    child: const Text('Aceptar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red, width: 1.5),
                    ),
                    onPressed: onRechazar,
                    child: const Text('Rechazar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
