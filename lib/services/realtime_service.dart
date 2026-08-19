import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Cliente WebSocket de HablaVas:
/// - Conductor: recibe viajes nuevos al instante (push, patron InDrive).
/// - Cliente: recibe la ubicacion en vivo del conductor de su viaje (tracking)
///   y las ofertas nuevas de los conductores (modal de propuestas de a 3).
/// El polling queda como fallback.
class RealtimeService {
  WebSocketChannel? _canal;
  StreamSubscription? _sub;
  void Function(Map<String, dynamic>)? onViajeNuevo;
  void Function(int viajeId, double lat, double lng)? onUbicacionConductor;
  void Function(int viajeId, int ofertaId, double precio)? onOfertaNueva;
  void Function(Map<String, dynamic>)? onViajeAceptado;
  void Function()? onConductoresActualizados;
  bool get conectado => _canal != null;

  /// Conexion del conductor: recibe carreras nuevas.
  Future<bool> conectar() => _conectar('ws/conductores');

  /// Conexion del cliente: recibe la ubicacion del conductor (tracking).
  Future<bool> conectarCliente() => _conectar('ws/clientes');

  Future<bool> _conectar(String path) async {
    await desconectar();
    final token = await ApiClient.obtenerToken();
    if (token == null) return false;

    // http -> ws, https -> wss
    final wsUrl = ApiConfig.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    try {
      _canal = WebSocketChannel.connect(Uri.parse('$wsUrl/$path?token=$token'));
      _sub = _canal!.stream.listen(
        (mensaje) {
          final datos = _decodificar(mensaje);
          if (datos == null) return;
          if (datos['tipo'] == 'viaje_nuevo') {
            onViajeNuevo?.call(datos);
          } else if (datos['tipo'] == 'ubicacion_conductor') {
            onUbicacionConductor?.call(
              (datos['viaje_id'] as num?)?.toInt() ?? 0,
              (datos['lat'] as num).toDouble(),
              (datos['lng'] as num).toDouble(),
            );
          } else if (datos['tipo'] == 'oferta_nueva') {
            onOfertaNueva?.call(
              (datos['viaje_id'] as num?)?.toInt() ?? 0,
              (datos['oferta_id'] as num?)?.toInt() ?? 0,
              (datos['precio_ofertado'] as num?)?.toDouble() ?? 0,
            );
          } else if (datos['tipo'] == 'viaje_aceptado') {
            // El cliente acepto la oferta del conductor: la carrera pasa a activa.
            onViajeAceptado?.call(datos);
          } else if (datos['tipo'] == 'conductores_actualizados') {
            // Un conductor se conecto/desconecto o recargo: refresca "motos
            // disponibles cerca" (lista + mapa) sin que el cliente haga nada.
            onConductoresActualizados?.call();
          }
        },
        onError: (_) => _canal = null,
        onDone: () => _canal = null,
        cancelOnError: true,
      );
      return true;
    } catch (_) {
      _canal = null;
      return false;
    }
  }

  Map<String, dynamic>? _decodificar(dynamic mensaje) {
    try {
      if (mensaje is String) {
        return jsonDecode(mensaje) as Map<String, dynamic>;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> desconectar() async {
    await _sub?.cancel();
    _sub = null;
    await _canal?.sink.close();
    _canal = null;
  }
}
