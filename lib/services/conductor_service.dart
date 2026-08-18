import 'dart:typed_data';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/conductor_model.dart';
import '../models/paquete_model.dart';
import '../models/viaje_model.dart';
import 'viaje_service.dart';

/// Unico service que sabe de /conductores/* y del saldo/recargas.
class ConductorService {
  static Future<Conductor> perfil() async {
    final data = await ApiClient.get(ApiConfig.conductorPerfil);
    return Conductor.desdeJson(data);
  }

  /// Documentos del conductor subidos (tipo, cara, url) desde la tabla
  /// documentos_conductores (el perfil usa esto, no los campos viejos).
  static Future<List<Map<String, dynamic>>> documentos() async {
    final data = await ApiClient.get(ApiConfig.conductorDocumentos) as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Activa el modo pasajero del conductor: crea su perfil de cliente en el
  /// backend (si no existe) para que pueda pedir carreras con la misma cuenta.
  static Future<Map<String, dynamic>> activarModoPasajero() async {
    return await ApiClient.post(ApiConfig.conductorPerfilPasajero) as Map<String, dynamic>;
  }

  static Future<Viaje?> viajeActivo() async {
    final data = await ApiClient.get(ApiConfig.conductorViajeActivo);
    if (data == null) return null;
    return Viaje.desdeJson(data);
  }

  static Future<Conductor> cambiarDisponibilidad({required bool disponible}) async {
    final data = await ApiClient.put(
      ApiConfig.conductorDisponibilidad,
      body: {'disponible': disponible},
    );
    return Conductor.desdeJson(data);
  }

  static Future<void> actualizarUbicacion({required double lat, required double lng}) async {
    await ApiClient.put(
      ApiConfig.conductorUbicacion,
      body: {'lat': lat, 'lng': lng},
    );
  }

  static Future<int> saldo() async {
    final data = await ApiClient.get(ApiConfig.conductorSaldo);
    return data['saldo_carreras'] as int;
  }

  static Future<List<Paquete>> paquetes() async {
    final data = await ApiClient.get(ApiConfig.conductorPaquetes) as List;
    return data.map((e) => Paquete.desdeJson(e as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> recargar({required int paqueteId, String metodo = 'yape'}) async {
    final data = await ApiClient.post(
      ApiConfig.conductorRecargar,
      body: {'paquete_id': paqueteId, 'metodo': metodo},
    );
    return data as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> confirmarRecarga(int recargaId) async {
    final data = await ApiClient.post(
      '${ApiConfig.baseUrl}/api/v1/recargas/$recargaId/confirmar',
    );
    return data as Map<String, dynamic>;
  }

  static Future<List<Viaje>> historial() async {
    final data = await ApiClient.get(ApiConfig.conductorHistorial) as List;
    return data.map((e) => Viaje.desdeJson(e as Map<String, dynamic>)).toList();
  }

  /// Sube un documento (foto/dni/licencia/antecedentes) a ImageKit.
  static Future<Map<String, dynamic>> subirDocumento({
    required String tipo,
    String? cara,
    required Uint8List bytes,
    required String nombreArchivo,
  }) async {
    final data = await ApiClient.postFile(
      '${ApiConfig.baseUrl}/api/v1/conductores/documentos',
      campo: 'archivo',
      bytes: bytes,
      nombreArchivo: nombreArchivo,
      query: {'tipo': tipo, if (cara != null) 'cara': cara},
    );
    return data as Map<String, dynamic>;
  }
}
