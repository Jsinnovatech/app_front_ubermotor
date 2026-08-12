import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';

/// Mapa de viajes disponibles (OpenStreetMap, sin API key) replicando el
/// diseno de Stitch: fondo de mapa + pin central y pines por viaje.
/// Cada viaje muestra origen (verde) y destino (negro). Al tocar un pin
/// se abre el viaje para aceptar.
/// El mapa se CENTRA en la ubicacion actual del conductor (latConductor/
/// lngConductor) y dibuja el circulo de rango (radioKm). Cuando la posicion
/// cambia, la camara se mueve a la nueva ubicacion.
class MapaViajes extends StatefulWidget {
  final List<Viaje> viajes;
  final void Function(Viaje viaje)? onViajeTap;
  final double? latConductor;
  final double? lngConductor;
  final double radioKm;

  const MapaViajes({
    super.key,
    required this.viajes,
    this.onViajeTap,
    this.latConductor,
    this.lngConductor,
    this.radioKm = 5,
  });

  @override
  State<MapaViajes> createState() => _MapaViajesState();
}

class _MapaViajesState extends State<MapaViajes> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant MapaViajes oldWidget) {
    super.didUpdateWidget(oldWidget);
    final cambioPosicion =
        oldWidget.latConductor != widget.latConductor ||
        oldWidget.lngConductor != widget.lngConductor;
    if (cambioPosicion &&
        widget.latConductor != null &&
        widget.lngConductor != null &&
        _mapController.camera != null) {
      // Mueve la camara a la nueva posicion del conductor (sin saltar al
      // centro del mundo). Solo cuando hay una posicion real.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(
          LatLng(widget.latConductor!, widget.lngConductor!),
          _mapController.camera.zoom,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pines = <Marker>[];
    if (widget.viajes.isNotEmpty) {
      for (var v in widget.viajes) {
        pines.add(
          Marker(
            point: LatLng(v.origenLat, v.origenLng),
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => widget.onViajeTap?.call(v),
              child: const Icon(Icons.location_on, color: AppColors.green, size: 34),
            ),
          ),
        );
        pines.add(
          Marker(
            point: LatLng(v.destinoLat, v.destinoLng),
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => widget.onViajeTap?.call(v),
              child: const Icon(Icons.sports_motorsports, color: AppColors.black, size: 28),
            ),
          ),
        );
      }
    }

    final tienePosicion = widget.latConductor != null && widget.lngConductor != null;
    final centro = LatLng(
      widget.latConductor ?? -12.0464,
      widget.lngConductor ?? -77.0428,
    );

    final circuloRango = <CircleMarker>[];
    if (tienePosicion) {
      circuloRango.add(
        CircleMarker(
          point: centro,
          radius: widget.radioKm * 1000, // km -> metros
          useRadiusInMeter: true,
          color: AppColors.yellow.withOpacity(0.10),
          borderColor: AppColors.yellow,
          borderStrokeWidth: 2,
        ),
      );
    }

    final pinConductor = <Marker>[
      if (tienePosicion)
        Marker(
          point: centro,
          width: 48,
          height: 48,
          child: const Icon(
            Icons.two_wheeler,
            color: AppColors.black,
            size: 44,
            shadows: [
              Shadow(color: AppColors.yellow, offset: Offset(-1, -1)),
              Shadow(color: AppColors.yellow, offset: Offset(1, -1)),
              Shadow(color: AppColors.yellow, offset: Offset(-1, 1)),
              Shadow(color: AppColors.yellow, offset: Offset(1, 1)),
            ],
          ),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: centro,
          initialZoom: 13,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.jsinnovatech.ubermotor',
          ),
          CircleLayer(circles: circuloRango),
          MarkerLayer(markers: [...pinConductor, ...pines]),
        ],
      ),
    );
  }
}
