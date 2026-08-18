import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/dialogo_calificacion.dart';
import '../../../models/viaje_model.dart';
import '../../../services/calificacion_service.dart';
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
  List<LatLng> _ruta = [];

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
    _cargarRuta();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refrescarEstado());
  }

  /// Carga la ruta origen->destino (OSRM) para dibujarla en el mapa.
  Future<void> _cargarRuta() async {
    try {
      final puntos = await ViajeService.ruta(_viaje.id);
      if (!mounted) return;
      setState(() {
        _ruta = puntos
            .map((p) => LatLng(p['lat']!, p['lng']!))
            .toList();
      });
    } catch (_) {}
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
        final anterior = _viaje.estado;
        setState(() => _viaje = actual);
        _avisarCambio(anterior, actual.estado);
      }
    } catch (_) {}
  }

  /// Avisa al cliente cuando el conductor llega o cuando termina el viaje.
  void _avisarCambio(String anterior, String nuevo) {
    if (nuevo == 'llegado' && anterior != 'llegado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.yellow,
          content: Text(
            '🛵 Tu conductor llegó, sube al moto',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.black),
          ),
        ),
      );
    } else if (nuevo == 'completado' && anterior != 'completado') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.green,
          content: Text(
            '✅ Llegaste a tu destino, califica a tu conductor',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.white),
          ),
        ),
      );
    }
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
      body: Stack(
        children: [
          // Mapa a pantalla completa (estilo InDrive)
          Positioned.fill(
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
                // Ruta origen->destino (linea azul por calles)
                if (_ruta.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _ruta,
                        color: AppColors.blue,
                        strokeWidth: 5,
                      ),
                    ],
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
          // Panel deslizante con el estado y los datos del viaje
          DraggableScrollableSheet(
            initialChildSize: 0.32,
            minChildSize: 0.18,
            maxChildSize: 0.8,
            snap: true,
            snapSizes: const [0.32, 0.6],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Manija de arrastre
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Banner de estado
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
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
                    const SizedBox(height: 14),
                    // Datos del conductor
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
                if (v.estado == 'asignado' || v.estado == 'llegado') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.red,
                        side: const BorderSide(color: AppColors.red),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _confirmarCancelar,
                      icon: const Icon(Icons.close, size: 20),
                      label: const Text('CANCELAR VIAJE', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
                if (v.estado == 'completado') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.yellow,
                        foregroundColor: AppColors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _calificar,
                      icon: const Icon(Icons.star, size: 20),
                      label: const Text('CALIFICAR CONDUCTOR', style: TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Confirma y cancela el viaje (solo disponible en asignado/llegado).
  Future<void> _confirmarCancelar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar viaje', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('¿Seguro que quieres cancelar el viaje?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await ViajeService.cancelar(_viaje.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Viaje cancelado. La carrera fue devuelta.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    }
  }

  /// Abre el dialogo de estrellas + comentario para calificar al conductor.
  Future<void> _calificar() async {
    final resultado = await mostrarDialogoCalificacion(
      context,
      titulo: 'Califica al conductor',
    );
    if (resultado == null || !mounted) return;

    try {
      await CalificacionService.calificar(
        viajeId: _viaje.id,
        puntaje: resultado.puntaje,
        comentario: resultado.comentario,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calificación registrada: ${resultado.puntaje} estrellas')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    }
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
