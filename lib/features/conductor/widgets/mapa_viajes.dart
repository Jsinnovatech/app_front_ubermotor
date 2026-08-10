import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';

/// Mapa de viajes disponibles (OpenStreetMap, sin API key) replicando el
/// diseno de Stitch: fondo de mapa + pin central y pines por viaje.
/// Cada viaje muestra origen (verde) y destino (negro).
class MapaViajes extends StatelessWidget {
  final List<Viaje> viajes;

  const MapaViajes({super.key, required this.viajes});

  @override
  Widget build(BuildContext context) {
    final pines = <Marker>[];
    if (viajes.isNotEmpty) {
      for (var v in viajes) {
        pines.add(
          Marker(
            point: LatLng(v.origenLat, v.origenLng),
            width: 26,
            height: 26,
            child: const Icon(Icons.location_on, color: AppColors.green, size: 26),
          ),
        );
        pines.add(
          Marker(
            point: LatLng(v.destinoLat, v.destinoLng),
            width: 26,
            height: 26,
            child: const Icon(Icons.sports_motorsports, color: AppColors.black, size: 22),
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(-12.0464, -77.0428), // Lima
          initialZoom: 12,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.jsinnovatech.ubermotor',
          ),
          MarkerLayer(markers: pines),
        ],
      ),
    );
  }
}
