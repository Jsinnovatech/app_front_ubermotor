import 'dart:convert';
import 'package:http/http.dart' as http;

/// Resultado de una sugerencia de direccion (autocompletado).
class SugerenciaLugar {
  final String nombre;
  final double lat;
  final double lng;

  SugerenciaLugar({required this.nombre, required this.lat, required this.lng});

  factory SugerenciaLugar.desdeJson(Map<String, dynamic> json) {
    return SugerenciaLugar(
      nombre: json['formatted'] ?? json['name'] ?? 'Ubicación',
      lat: (json['lat'] as num?)?.toDouble() ?? 0,
      lng: (json['lon'] as num?)?.toDouble() ?? 0,
    );
  }
}

/// Geocodificacion con Geoapify (tipo Google, gratis 3000 req/dia):
/// - Autocompletado desde 1 caracter mientras se escribe.
/// - Reverse: convertir una coordenada GPS en direccion legible.
class GeocodingService {
  static const String _key = '4848f78652284954aa22131303d67fdc';
  static const _api = 'https://api.geoapify.com/v1/geocode';

  /// Sugerencias de lugares mientras el usuario escribe (autocomplete).
  /// Geoapify responde desde 1 caracter, filtrado a Peru (bias hacia Lima).
  static Future<List<SugerenciaLugar>> autocompletar(String query, {double? lat, double? lng}) async {
    if (query.trim().isEmpty) return const [];
    try {
      final params = {
        'text': query.trim(),
        'apiKey': _key,
        'limit': '5',
        'lang': 'es',
        'country': 'peru',
        'bias': lat != null && lng != null ? 'proximity:$lng,$lat' : 'proximity:-77.02824,-12.04318',
      };
      final uri = Uri.parse('$_api/search').replace(queryParameters: params);
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return const [];
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];
      return features
          .map((f) {
            final props = (f as Map)['properties'] as Map<String, dynamic>? ?? {};
            final geom = (f['geometry'] as Map?)?['coordinates'] as List? ?? [0, 0];
            return SugerenciaLugar(
              nombre: props['formatted'] ?? 'Ubicación',
              lat: (geom[1] as num?)?.toDouble() ?? 0,
              lng: (geom[0] as num?)?.toDouble() ?? 0,
            );
          })
          .where((s) => s.lat != 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Convierte una coordenada en direccion legible ("Av. Larco 800, Miraflores").
  static Future<String?> reverse(double lat, double lng) async {
    try {
      final params = {
        'lat': '$lat',
        'lon': '$lng',
        'apiKey': _key,
        'lang': 'es',
      };
      final uri = Uri.parse('$_api/reverse').replace(queryParameters: params);
      final resp = await http.get(uri);
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final features = data['features'] as List? ?? [];
      if (features.isEmpty) return null;
      final props = (features[0] as Map)['properties'] as Map<String, dynamic>? ?? {};
      return props['formatted'] as String?;
    } catch (_) {
      return null;
    }
  }
}
