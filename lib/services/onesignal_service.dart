import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../core/config/api_config.dart';
import '../core/navigation_service.dart';

/// Puente centralizado con OneSignal (push notifications). Único lugar de la
/// app que llama al SDK de OneSignal.
///
/// El WebSocket solo entrega mensajes con la app abierta; el push despierta el
/// teléfono aunque la app esté cerrada o en segundo plano. El dispositivo se
/// vincula al usuario real con [vincularUsuario] (external id), asi el backend
/// puede apuntar con `include_external_user_ids`.
class PushService {
  static bool _inicializado = false;

  /// Se conserva para que el observer del SDK (que se guarda débil) no se
  /// libere y el diálogo de verificación pueda aparecer.
  static OnPushSubscriptionChangeObserver? _observer;
  static bool _dialogoMostrado = false;

  /// Arranca OneSignal. No pide permiso aquí: el permiso se pide cuando el
  /// usuario toca "Got it" en el diálogo de verificación (estándar OneSignal).
  static Future<void> inicializar() async {
    const appId = ApiConfig.onesignalAppId;
    if (appId.isEmpty) return;

    try {
      await OneSignal.initialize(appId);
      _observer = (stateChanges) {
        _evaluarSuscripcion(stateChanges.current.id);
      };
      OneSignal.User.pushSubscription.addObserver(_observer!);
      // El id puede ya estar asignado antes de registrar el observer: evalúalo
      // de inmediato también.
      _evaluarSuscripcion(OneSignal.User.pushSubscription.id);

      OneSignal.Notifications.addClickListener((event) {
        _abrirPantallaPorPush(event.notification.additionalData);
      });
      _inicializado = true;
    } catch (_) {
      _inicializado = false;
    }
  }

  /// Muestra el diálogo de verificación una sola vez cuando el dispositivo ya
  /// está registrado (id real asignado por el servidor, no el `local-`).
  static void _evaluarSuscripcion(String? id) {
    final registrado = id != null && id.isNotEmpty && !id.startsWith('local-');
    if (!registrado) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = navigatorKey.currentContext;
      if (context == null || _dialogoMostrado) return;
      _dialogoMostrado = true;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Your OneSignal SDK integration is complete!',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: const Text(
            'You can now send Push Notifications & In-App Messages through OneSignal. '
            'Tap below to enable push notifications.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                OneSignal.Notifications.requestPermission(true);
              },
              child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      );
    });
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
