import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';
import '../../../services/realtime_service.dart';
import '../../../services/viaje_service.dart';

/// Seguimiento del viaje (cliente). Cambia segun el estado:
/// - asignado: "Tu conductor esta en camino" (pin se mueve en vivo)
/// - llegado:  "Tu conductor llego, sube al moto"
/// - en_curso: "En viaje al destino" (pin se mueve)
/// - completado: "Llegaste a tu destino" + boton calificar
class SeguimientoViajeScreen extends StatefulWidget {
  final Viaje viaje;
  const SeguimientoViajeScreen({super.key, required this.viaje});

  @override
  State<SeguimientoViajeScreen> createState() => _SeguimientoViajeScreenState();
}

class _SeguimientoViajeScreenState extends State<SeguimientoViajeScreen> {
  late Viaje _viaje;
  final _realtime = RealtimeService();
  Timer? _timer;
  double? _conductorLat;
  double? _conductorLng;

  @override
  void initState() {
    super.initState();
    _viaje = widget.viaje;
    _conductorLat = _viaje.origenLat;
    _conductorLng = _viaje.origenLng;
    _realtime.onUbicacionConductor = (viajeId, lat, lng) {
      if (!mounted || viajeId != _viaje.id) return;
      setState(() {
        _conductorLat = lat;
        _conductorLng = lng;
      });
    };
    _realtime.conectarCliente();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refrescarEstado());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _realtime.desconectar();
    super.dispose();
  }

  Future<void> _refrescarEstado() async {
    try {
      final actual = await ViajeService.obtenerEstado(_viaje.id);
      if (!mounted) return;
      if (actual != null && actual.estado != _viaje.estado) {
        setState(() => _viaje = actual);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final v = _viaje;
    final estado = v.estado;

    final (titulo, subtitulo, color) = switch (estado) {
      'asignado' => ('Tu conductor está en camino', 'Dirígete al punto de encuentro', AppColors.blue),
      'llegado' => ('Tu conductor llegó', 'Sube al moto para iniciar el viaje', AppColors.yellow),
      'en_curso' => ('En viaje a tu destino', 'Siéntete cómodo, ya casi llegas', AppColors.green),
      _ => ('Llegaste a tu destino', 'Gracias por viajar con HablaVas', AppColors.green),
    };

    final conductorLat = _conductorLat ?? v.origenLat;
    final conductorLng = _conductorLng ?? v.origenLng;

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: const Text(
          'Tu viaje',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppColors.yellow),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: color,
            child: Row(
              children: [
                Icon(_iconoEstado(estado), color: AppColors.black, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.black),
                      ),
                      Text(
                        subtitulo,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.black),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(conductorLat, conductorLng),
                initialZoom: 14,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.jsinnovatech.ubermotor',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(conductorLat, conductorLng),
                      width: 44,
                      height: 44,
                      child: const Icon(Icons.two_wheeler, color: AppColors.yellow, size: 40),
                    ),
                    Marker(
                      point: LatLng(v.destinoLat, v.destinoLng),
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.flag, color: AppColors.green, size: 34),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.line))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (v.conductorNombre != null)
                  Row(
                    children: [
                      Icon(v.conductorFotoUrl != null ? Icons.person : Icons.person, size: 18, color: AppColors.yellow),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${v.conductorNombre} · ⭐ ${v.conductorRating?.toStringAsFixed(1) ?? '—'}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.black),
                        ),
                      ),
                      if (v.motoDescripcion != null)
                        Text(v.motoDescripcion!, style: const TextStyle(fontSize: 13, color: AppColors.textDim)),
                    ],
                  ),
                const SizedBox(height: 8),
                _fila(Icons.place, v.origenDireccion ?? 'Origen'),
                const SizedBox(height: 4),
                _fila(Icons.sports_motorsports, v.destinoDireccion ?? 'Destino'),
                const SizedBox(height: 10),
                Text(
                  'S/ ${v.tarifa.toStringAsFixed(2)} · ${v.metodoPagoCliente}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconoEstado(String estado) {
    return switch (estado) {
      'asignado' => Icons.navigation,
      'llegado' => Icons.two_wheeler,
      'en_curso' => Icons.arrow_forward,
      _ => Icons.flag,
    };
  }

  Widget _fila(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 16, color: AppColors.yellow),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black)),
        ),
      ],
    );
  }
}
