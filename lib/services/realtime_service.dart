import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Cliente WebSocket del conductor: recibe viajes nuevos al instante (push,
/// patron InDrive). El polling de 5s queda como fallback.
class RealtimeService {
  WebSocketChannel? _canal;
  StreamSubscription? _sub;
  void Function(Map<String, dynamic>)? onViajeNuevo;
  bool get conectado => _canal != null;

  Future<bool> conectar() async {
    await desconectar();
    final token = await ApiClient.obtenerToken();
    if (token == null) return false;

    // http -> ws, https -> wss
    final wsUrl = ApiConfig.baseUrl
        .replaceFirst('https://', 'wss://')
        .replaceFirst('http://', 'ws://');
    try {
      _canal = WebSocketChannel.connect(Uri.parse('$wsUrl/ws/conductores?token=$token'));
      _sub = _canal!.stream.listen(
        (mensaje) {
          final datos = _decodificar(mensaje);
          if (datos != null && datos['tipo'] == 'viaje_nuevo') {
            onViajeNuevo?.call(datos);
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
