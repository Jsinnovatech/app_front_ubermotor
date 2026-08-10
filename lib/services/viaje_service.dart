import '../core/config/api_config.dart';
import '../core/network/api_client.dart';
import '../models/viaje_model.dart';

/// Unico service que sabe de /viajes/* (estados del ciclo de vida).
class ViajeService {
  static Future<List<Viaje>> disponibles() async {
    final data = await ApiClient.get(ApiConfig.viajesDisponibles) as List;
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

  static Future<Viaje> completar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeCompletar(viajeId));
    return Viaje.desdeJson(data);
  }

  static Future<Viaje> cancelar(int viajeId) async {
    final data = await ApiClient.post(ApiConfig.viajeCancelar(viajeId));
    return Viaje.desdeJson(data);
  }
}
