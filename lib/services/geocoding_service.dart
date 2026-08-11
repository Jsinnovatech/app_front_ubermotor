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
      nombre: json['display_name'] ?? json['name'] ?? 'Ubicación',
      lat: double.tryParse('${json['lat'] ?? '0'}') ?? 0,
      lng: double.tryParse('${json['lon'] ?? '0'}') ?? 0,
    );
  }
}

/// Geocodificacion con Nominatim (OpenStreetMap): gratis, sin API key.
/// - Autocompletar direcciones mientras se escribe (usado en el campo destino).
/// - Reverse: convertir una coordenada GPS en direccion legible.
class GeocodingService {
  static const _base = 'https://nominatim.openstreetmap.org';
  static const _userAgent = 'HablaVas/1.0';

  /// Sugerencias de lugares mientras el usuario escribe (autocomplete).
  static Future<List<SugerenciaLugar>> autocompletar(String query, {double? lat, double? lng}) async {
    if (query.trim().length < 3) return const [];
    try {
      final resp = await http.get(
        Uri.parse('$_base/search?q=${Uri.encodeQueryComponent(query.trim())}&format=json&limit=5&addressdetails=1&countrycodes=pe'),
        headers: {'User-Agent': _userAgent},
      );
      if (resp.statusCode != 200) return const [];
      final lista = jsonDecode(resp.body) as List;
      return lista
          .map((e) => SugerenciaLugar.desdeJson(e as Map<String, dynamic>))
          .where((s) => s.lat != 0)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Convierte una coordenada en direccion legible ("Av. Larco 800, Miraflores").
  static Future<String?> reverse(double lat, double lng) async {
    try {
      final resp = await http.get(
        Uri.parse('$_base/reverse?lat=$lat&lon=$lng&format=json&addressdetails=1'),
        headers: {'User-Agent': _userAgent},
      );
      if (resp.statusCode != 200) return null;
      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      return data['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
