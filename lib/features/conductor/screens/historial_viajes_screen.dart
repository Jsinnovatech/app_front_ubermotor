import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/estado_chip.dart';
import '../../../providers/conductor_provider.dart';
import '../../../services/calificacion_service.dart';

/// Historial de viajes del conductor (Rides). Replica el estilo de Stitch.
class HistorialViajesScreen extends StatefulWidget {
  const HistorialViajesScreen({super.key});

  @override
  State<HistorialViajesScreen> createState() => _HistorialViajesScreenState();
}

class _HistorialViajesScreenState extends State<HistorialViajesScreen> {
  final Set<int> _calificados = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConductorProvider>().cargarHistorial();
    });
  }

  Future<void> _calificar(int viajeId) async {
    final puntaje = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Califica el viaje', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('¿Cómo estuvo el viaje? Toca las estrellas.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                iconSize: 32,
                icon: Icon(i < 4 ? Icons.star_border : Icons.star, color: AppColors.yellow),
                onPressed: () => Navigator.of(ctx).pop(i + 1),
              );
            }),
          ),
        ],
      ),
    );
    if (puntaje == null || !mounted) return;

    try {
      await CalificacionService.calificar(viajeId: viajeId, puntaje: puntaje);
      setState(() => _calificados.add(viajeId));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificación registrada: $puntaje estrellas')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConductorProvider>();
    final historial = provider.historial;

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.gray,
        elevation: 0,
        title: const Text(
          'Mis viajes',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black),
        ),
      ),
      body: historial.isEmpty
          ? const Center(
              child: Text(
                'Aún no tienes viajes.',
                style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: historial.length,
              itemBuilder: (_, i) {
                final v = historial[i];
                final completado = v.estado == 'completado';
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  v.origenDireccion ?? 'Viaje #${v.id}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
                                ),
                                Text(
                                  '→ ${v.destinoDireccion ?? 'Destino'}',
                                  style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'S/ ${v.tarifa.toStringAsFixed(2)} · ${v.metodoPagoCliente}',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                                ),
                              ],
                            ),
                          ),
                          EstadoChip(estado: v.estado, color: AppColors.azulEstado(v.estado)),
                        ],
                      ),
                      if (completado && !_calificados.contains(v.id)) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.yellow),
                            onPressed: () => _calificar(v.id),
                            icon: const Icon(Icons.star, size: 18),
                            label: const Text('Calificar viaje', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }
}

