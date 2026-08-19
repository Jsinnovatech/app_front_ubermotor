import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';
import '../../../services/cliente_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/viaje_service.dart';

/// Modal que se abre justo despues de pedir un viaje.
///
/// Hoy (mientras el backend de ofertas de a 3 - Fase 3 del rediseno InDrive,
/// ver REDISENO_FLUJO_VIAJE_INDRIVE.md - todavia no existe) se comporta como
/// una pantalla de espera: muestra "Buscando conductor..." y se cierra solo
/// cuando el viaje pasa a 'asignado' (el primer conductor que acepta, igual
/// que el flujo actual). El parametro [realtime] no se usa todavia; cuando
/// se implementen los endpoints /viajes/{id}/ofertas se reemplaza el polling
/// por onOfertaNueva y se pinta la grilla de 3 propuestas real.
Future<Viaje?> mostrarModalPropuestas(
  BuildContext context, {
  required int viajeId,
  RealtimeService? realtime,
}) {
  return showModalBottomSheet<Viaje?>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EsperaConductor(viajeId: viajeId),
  );
}

class _EsperaConductor extends StatefulWidget {
  final int viajeId;
  const _EsperaConductor({required this.viajeId});

  @override
  State<_EsperaConductor> createState() => _EsperaConductorState();
}

class _EsperaConductorState extends State<_EsperaConductor> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Consulta cada 3s si ya hay conductor asignado (mismo patron que
    // _iniciarMonitoreoViaje en cliente_home_screen.dart).
    _timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      try {
        final viaje = await ClienteService.viajeActivo();
        if (!mounted) return;
        if (viaje != null && viaje.id == widget.viajeId && viaje.estado != 'solicitado') {
          Navigator.of(context).pop(viaje);
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _cancelar() async {
    try {
      await ViajeService.cancelar(widget.viajeId);
    } catch (_) {}
    if (mounted) Navigator.of(context).pop(null);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.yellow),
            const SizedBox(height: 20),
            const Text(
              'Buscando un conductor cerca...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.black),
            ),
            const SizedBox(height: 6),
            const Text(
              'Apenas un conductor acepte tu carrera, te avisamos aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: _cancelar,
              child: const Text(
                'Cancelar viaje',
                style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
