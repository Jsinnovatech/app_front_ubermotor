import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/viaje_model.dart';

/// Unico service que sabe de /viajes/* (estados del ciclo de vida).
class ViajeService {
  static Future<List<Viaje>> disponibles({
    double? lat,
    double? lng,
    double radioKm = 5,
  }) async {
    var url = ApiConfig.viajesDisponibles;
    if (lat != null && lng != null) {
      url += '?lat=$lat&lng=$lng&radio_km=$radioKm';
    }
    final data = await ApiClient.get(url) as List;
    return data.map((e) => Viaje.desdeJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Viaje> aceptar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeAceptar(viajeId));
    return Viaje.desdeJson(data);
  }

  static Future<Viaje> rechazar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeRechazar(viajeId));
    return Viaje.desdeJson(data);
  }

  static Future<Viaje> iniciar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeIniciar(viajeId));
    return Viaje.desdeJson(data);
  }

  static Future<Viaje> llegar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeLlegar(viajeId));
    return Viaje.desdeJson(data);
  }

  static Future<Viaje> completar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeCompletar(viajeId));
    return Viaje.desdeJson(data);
  }

  static Future<Viaje> cancelar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeCancelar(viajeId));
    return Viaje.desdeJson(data);
  }

  // ─── Ofertas (flujo InDrive) ────────────────────────────────────────────

  /// El conductor oferta su precio sobre un viaje 'solicitado'. NO consume
  /// saldo; se consume cuando el cliente acepta la oferta.
  static Future<Map<String, dynamic>> crearOferta({
    required int viajeId,
    required double precio,
  }) async {
    final data = await ApiClient.post(
      ApiConfig.viajeCrearOferta(viajeId),
      body: {'precio_ofertado': (precio * 100).round() / 100},
    );
    return data as Map<String, dynamic>;
  }

  /// El conductor retira su oferta antes de que venza (30s).
  static Future<void> retirarOferta({
    required int viajeId,
    required int ofertaId,
  }) async {
    await ApiClient.delete(ApiConfig.viajeRetirarOferta(viajeId, ofertaId));
  }

  /// Propuestas activas del viaje para el cliente, de a 3 (offset 0, 3, 6...).
  static Future<List<ViajeOferta>> ofertas(int viajeId, {int offset = 0}) async {
    final data = await ApiClient.get(
      '${ApiConfig.viajeOfertas(viajeId)}?offset=$offset',
    ) as List;
    return data.map((e) => ViajeOferta.desdeJson(e as Map<String, dynamic>)).toList();
  }

  /// El cliente acepta la oferta: consume el saldo del conductor y asigna.
  static Future<Viaje> aceptarOferta({
    required int viajeId,
    required int ofertaId,
  }) async {
    final data = await ApiClient.post(ApiConfig.viajeAceptarOferta(viajeId, ofertaId));
    return Viaje.desdeJson(data);
  }

  static Future<Viaje?> obtenerEstado(int viajeId) async {
    final data = await ApiClient.get('${ApiConfig.baseUrl}/api/v1/viajes/$viajeId');
    return Viaje.desdeJson(data);
  }

  /// Ruta real por calles del viaje (OSRM). Devuelve la lista de {lat, lng}.
  static Future<List<Map<String, double>>> ruta(int viajeId) async {
    final data = await ApiClient.get('${ApiConfig.baseUrl}/api/v1/viajes/$viajeId/ruta');
    final puntos = (data as Map)['puntos'] as List? ?? [];
    return puntos
        .map((p) => {'lat': (p['lat'] as num).toDouble(), 'lng': (p['lng'] as num).toDouble()})
        .toList();
  }

  /// Ruta real por calles desde la posicion EN VIVO del conductor hasta el
  /// punto de recojo. Se recalcula en cada llamada (el conductor se mueve).
  /// Vacia si el viaje ya no esta 'asignado'/'llegado'.
  static Future<List<Map<String, double>>> rutaConductor(int viajeId) async {
    final data = await ApiClient.get('${ApiConfig.baseUrl}/api/v1/viajes/$viajeId/ruta-conductor');
    final puntos = (data as Map)['puntos'] as List? ?? [];
    return puntos
        .map((p) => {'lat': (p['lat'] as num).toDouble(), 'lng': (p['lng'] as num).toDouble()})
        .toList();
  }
}
