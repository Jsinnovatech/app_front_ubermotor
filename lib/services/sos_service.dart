import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Alerta de emergencia (SOS): el front confirma con 2 presiones y llama
/// este endpoint, que registra la alerta y dispara el webhook a la policia.
class SosService {
  static Future<Map<String, dynamic>> activar({required double lat, required double lng}) async {
    final data = await ApiClient.post(
      '${ApiConfig.baseUrl}/api/v1/sos',
      body: {'lat': lat, 'lng': lng},
    );
    return data as Map<String, dynamic>;
  }
}
