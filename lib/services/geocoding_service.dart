import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Resultado de una sugerencia de direccion (autocompletado).
class SugerenciaLugar {
  final String nombre;
  final double lat;
  final double lng;

  SugerenciaLugar({required this.nombre, required this.lat, required this.lng});

  factory SugerenciaLugar.desdeJson(Map<String, dynamic> json) {
    return SugerenciaLugar(
      nombre: json['nombre'] ?? 'Ubicación',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lng'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Geocodificacion via el BACKEND (Geoapify en el servidor, key protegida):
/// - Autocompletado desde 1 caracter mientras se escribe.
/// - Reverse: convertir una coordenada GPS en direccion legible.
class GeocodingService {
  static Future<List<SugerenciaLugar>> autocompletar(String query, {double? lat, double? lng}) async {
    if (query.trim().isEmpty) return const [];
    try {
      var url = '${ApiConfig.baseUrl}/api/v1/geocoding/search?q=${Uri.encodeQueryComponent(query.trim())}';
      if (lat != null && lng != null) url += '&lat=$lat&lng=$lng';
      final data = await ApiClient.get(url) as List;
      return data.map((e) => SugerenciaLugar.desdeJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Convierte una coordenada en direccion legible.
  static Future<String?> reverse(double lat, double lng) async {
    try {
      final data = await ApiClient.get('${ApiConfig.baseUrl}/api/v1/geocoding/reverse?lat=$lat&lng=$lng');
      return (data as Map)['direccion'] as String?;
    } catch (_) {
      return null;
    }
  }
}
