import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';

/// Mapa de viajes disponibles (OpenStreetMap, sin API key) replicando el
/// diseno de Stitch: fondo de mapa + pin central y pines por viaje.
/// Cada viaje muestra origen (verde) y destino (negro). Al tocar un pin
/// se abre el viaje para aceptar.
class MapaViajes extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final pines = <Marker>[];
    if (viajes.isNotEmpty) {
      for (var v in viajes) {
        pines.add(
          Marker(
            point: LatLng(v.origenLat, v.origenLng),
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => onViajeTap?.call(v),
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
              onTap: () => onViajeTap?.call(v),
              child: const Icon(Icons.sports_motorsports, color: AppColors.black, size: 28),
            ),
          ),
        );
      }
    }

    final tienePosicion = latConductor != null && lngConductor != null;
    final centro = LatLng(
      latConductor ?? -12.0464,
      lngConductor ?? -77.0428,
    );

    final circuloRango = <CircleMarker>[];
    if (tienePosicion) {
      circuloRango.add(
        CircleMarker(
          point: centro,
          radius: radioKm * 1000, // km -> metros
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
          width: 44,
          height: 44,
          child: const Icon(Icons.two_wheeler, color: AppColors.yellow, size: 40),
        ),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
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
