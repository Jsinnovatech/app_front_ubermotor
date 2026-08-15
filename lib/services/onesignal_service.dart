import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../core/config/api_config.dart';
import '../core/navigation_service.dart';

/// Puente con OneSignal (push notifications).
///
/// El WebSocket solo entrega mensajes con la app abierta; el push despierta el
/// telefono aunque la app este cerrada o en segundo plano. El dispositivo se
/// vincula al usuario real con [vincularUsuario] (external id), asi el backend
/// puede apuntar con `include_external_user_ids`.
class PushService {
  static bool _inicializado = false;

  /// Arranca OneSignal y pide permiso de notificaciones. Sin appId definido
  /// (dart-define) no hace nada, asi la app no rompe en builds sin push.
  static Future<void> inicializar() async {
    const appId = ApiConfig.onesignalAppId;
    if (appId.isEmpty) return;

    try {
      await OneSignal.initialize(appId);
      await OneSignal.Notifications.requestPermission(true);
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        _abrirPantallaPorPush(data);
      });
      _inicializado = true;
    } catch (_) {
      _inicializado = false;
    }
  }

  /// Vincula este dispositivo al usuario logueado para que el backend le pueda
  /// mandar notificaciones (conductor_{usuario_id} / cliente_{usuario_id}).
  static Future<void> vincularUsuario({
    required int usuarioId,
    required String tipo,
  }) async {
    if (!_inicializado) return;
    final externalId = tipo == 'conductor'
        ? 'conductor_$usuarioId'
        : 'cliente_$usuarioId';
    try {
      await OneSignal.login(externalId);
    } catch (_) {}
  }

  /// Desvincula el dispositivo al cerrar sesion (otro usuario podria entrar).
  static Future<void> cerrarSesion() async {
    if (!_inicializado) return;
    try {
      await OneSignal.logout();
    } catch (_) {}
  }

  /// Al tocar la notificacion, vuelve a la pantalla raiz: el _Portero decide
  /// que home mostrar segun la sesion y cada pantalla reconcilia su estado
  /// (viaje-activo) al construirse.
  static void _abrirPantallaPorPush(Map<String, dynamic>? data) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) return;
    navigator.popUntil((r) => r.isFirst);
  }
}
