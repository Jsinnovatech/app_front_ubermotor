import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/estado_chip.dart';
import '../../../providers/conductor_provider.dart';

/// Historial de viajes del conductor (Rides). Replica el estilo de Stitch.
class HistorialViajesScreen extends StatefulWidget {
  const HistorialViajesScreen({super.key});

  @override
  State<HistorialViajesScreen> createState() => _HistorialViajesScreenState();
}

class _HistorialViajesScreenState extends State<HistorialViajesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConductorProvider>().cargarHistorial();
    });
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
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line, width: 1),
                  ),
                  child: Row(
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
                );
              },
            ),
    );
  }
}
