import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Calificacion de viajes completados (1-5) y ranking de conductores.
class CalificacionService {
  static Future<void> calificar({
    required int viajeId,
    required int puntaje,
    String? comentario,
  }) async {
    await ApiClient.post(
      '${ApiConfig.baseUrl}/api/v1/calificaciones',
      body: {'viaje_id': viajeId, 'puntaje': puntaje, if (comentario != null) 'comentario': comentario},
    );
  }
}
