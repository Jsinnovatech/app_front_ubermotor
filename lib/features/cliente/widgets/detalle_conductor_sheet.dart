import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/conductor_disponible_model.dart';

/// Detalle del conductor que el cliente ve al tocar una moto: reputacion,
/// viajes, distancia y datos de la moto.
class DetalleConductorSheet extends StatelessWidget {
  final ConductorDisponible conductor;

  const DetalleConductorSheet({super.key, required this.conductor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.yellow,
                backgroundImage: conductor.fotoUrl != null ? NetworkImage(conductor.fotoUrl!) : null,
                child: conductor.fotoUrl == null
                    ? const Icon(Icons.two_wheeler, size: 30, color: AppColors.black)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conductor.nombre,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${conductor.distanciaKm.toStringAsFixed(1)} km de distancia',
                      style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _reputacion(Icons.star, conductor.ratingPromedio.toStringAsFixed(1), 'Rating'),
              Container(width: 1, height: 40, color: AppColors.line),
              _reputacion(Icons.directions_bike, '${conductor.viajesCompletados}', 'Viajes'),
              Container(width: 1, height: 40, color: AppColors.line),
              _reputacion(Icons.speed, '${conductor.moto.marca ?? 'Moto'}', 'Vehiculo'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('MOTO', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textDim)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (conductor.moto.fotoUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(conductor.moto.fotoUrl!, width: 64, height: 64, fit: BoxFit.cover),
                      )
                    else
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.yellowSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.two_wheeler, color: AppColors.black),
                      ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${conductor.moto.marca ?? '—'} ${conductor.moto.modelo ?? ''}'.trim(),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.black),
                          ),
                          Text(
                            'Placa: ${conductor.moto.placa ?? '—'} · ${conductor.moto.color ?? ''}',
                            style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reputacion(IconData icono, String valor, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icono, size: 20, color: AppColors.yellow),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
