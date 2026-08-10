import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/viaje_model.dart';

/// Unico service que sabe de /clientes/*.
class ClienteService {
  static Future<Viaje> solicitarViaje({
    required double origenLat,
    required double origenLng,
    required double destinoLat,
    required double destinoLng,
    String? origenDireccion,
    String? destinoDireccion,
    required double tarifa,
    String metodoPago = 'yape',
  }) async {
    final data = await ApiClient.post(
      ApiConfig.clienteSolicitarViaje,
      body: {
        'origen_lat': origenLat,
        'origen_lng': origenLng,
        'destino_lat': destinoLat,
        'destino_lng': destinoLng,
        'origen_direccion': origenDireccion,
        'destino_direccion': destinoDireccion,
        'tarifa': tarifa,
        'metodo_pago_cliente': metodoPago,
      },
    );
    return Viaje.desdeJson(data);
  }

  static Future<List<Viaje>> historial() async {
    final data = await ApiClient.get(ApiConfig.clienteHistorial) as List;
    return data.map((e) => Viaje.desdeJson(e as Map<String, dynamic>)).toList();
  }
}
