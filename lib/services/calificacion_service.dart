import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

class RankingItem {
  final int conductorId;
  final String nombre;
  final double rating;
  final int viajes;
  final String? fotoUrl;

  RankingItem({
    required this.conductorId,
    required this.nombre,
    required this.rating,
    required this.viajes,
    this.fotoUrl,
  });

  factory RankingItem.desdeJson(Map<String, dynamic> json) {
    return RankingItem(
      conductorId: json['conductor_id'],
      nombre: json['nombre'],
      rating: (json['rating_promedio'] as num).toDouble(),
      viajes: json['viajes_completados'] ?? 0,
      fotoUrl: json['foto_url'],
    );
  }
}

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

  static Future<List<RankingItem>> ranking() async {
    final data = await ApiClient.get('${ApiConfig.baseUrl}/api/v1/calificaciones/ranking') as List;
    return data.map((e) => RankingItem.desdeJson(e as Map<String, dynamic>)).toList();
  }
}
