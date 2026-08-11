import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/estado_chip.dart';
import '../../../models/viaje_model.dart';
import '../../../services/calificacion_service.dart';
import '../../../services/conductor_service.dart';

/// Historial de viajes del conductor (Rides). Carga directa del service,
/// sin pasar por el provider global, con estados de carga/error visibles
/// (nada de errores tragados en silencio).
class HistorialViajesScreen extends StatefulWidget {
  const HistorialViajesScreen({super.key});

  @override
  State<HistorialViajesScreen> createState() => _HistorialViajesScreenState();
}

class _HistorialViajesScreenState extends State<HistorialViajesScreen> {
  final Set<int> _calificados = {};
  late Future<List<Viaje>> _futuroHistorial;

  @override
  void initState() {
    super.initState();
    _futuroHistorial = _cargar();
  }

  Future<List<Viaje>> _cargar() {
    return ConductorService.historial();
  }

  void _reintentar() {
    setState(() => _futuroHistorial = _cargar());
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificación registrada: $puntaje estrellas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: const Text(
          'Mis viajes',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.yellow),
        ),
        iconTheme: const IconThemeData(color: AppColors.yellow),
      ),
      body: FutureBuilder<List<Viaje>>(
        future: _futuroHistorial,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 40, color: AppColors.textDim),
                    const SizedBox(height: 12),
                    Text(
                      'No se pudo cargar tu historial:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: _reintentar,
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.yellow),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            );
          }

          final historial = snapshot.data ?? [];
          if (historial.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes viajes.',
                style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: historial.length,
            itemBuilder: (_, i) {
              final v = historial[i];
              final completado = v.estado == 'completado';
              final filaPar = i % 2 == 0;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: filaPar ? AppColors.white : AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.black,
                          child: v.riderFotoUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    v.riderFotoUrl!,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Icon(Icons.person, size: 20, color: AppColors.yellow),
                                  ),
                                )
                              : const Icon(Icons.person, size: 20, color: AppColors.yellow),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      v.riderNombre ?? 'Cliente',
                                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (v.riderRating != null) ...[
                                    const Icon(Icons.star, size: 14, color: AppColors.yellow),
                                    const SizedBox(width: 2),
                                    Text(
                                      v.riderRating!.toStringAsFixed(1),
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.black),
                                    ),
                                  ],
                                ],
                              ),
                              Text(
                                v.origenDireccion ?? 'Viaje #${v.id}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '→ ${v.destinoDireccion ?? 'Destino'}',
                                style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
                                overflow: TextOverflow.ellipsis,
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
          );
        },
      ),
    );
  }
}
