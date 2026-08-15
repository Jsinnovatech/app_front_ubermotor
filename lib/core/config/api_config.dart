/// Unica fuente de verdad de URLs del backend. En Railway se configura la
/// variable de entorno API_BASE_URL (via --dart-define) al compilar Flutter Web.
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://appbackubermotor-production.up.railway.app',
  );

  // Notificaciones push OneSignal. El APP_ID se configura en el build:
  // flutter build apk --dart-define=ONESIGNAL_APP_ID=<tu-app-id>
  static const String onesignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: '',
  );

  // Auth
  static const String registro = '$baseUrl/auth/registro';
  static const String login = '$baseUrl/auth/login';
  static const String me = '$baseUrl/auth/me';

  // Conductores
  static const String conductorPerfil = '$baseUrl/api/v1/conductores/perfil';
  static const String conductorDisponibilidad = '$baseUrl/api/v1/conductores/disponibilidad';
  static const String conductorUbicacion = '$baseUrl/api/v1/conductores/ubicacion';
  static const String conductorSaldo = '$baseUrl/api/v1/conductores/saldo';
  static const String conductorPaquetes = '$baseUrl/api/v1/conductores/paquetes';
  static const String conductorRecargar = '$baseUrl/api/v1/conductores/recargar';
  static const String conductorHistorial = '$baseUrl/api/v1/conductores/historial';
  static const String conductorViajeActivo = '$baseUrl/api/v1/conductores/viaje-activo';

  // Viajes
  static const String viajesDisponibles = '$baseUrl/api/v1/viajes/disponibles';
  static String viajeAceptar(int id) => '$baseUrl/api/v1/viajes/$id/aceptar';
  static String viajeRechazar(int id) => '$baseUrl/api/v1/viajes/$id/rechazar';
  static String viajeLlegar(int id) => '$baseUrl/api/v1/viajes/$id/llegar';
  static String viajeIniciar(int id) => '$baseUrl/api/v1/viajes/$id/iniciar';
  static String viajeCompletar(int id) => '$baseUrl/api/v1/viajes/$id/completar';
  static String viajeCancelar(int id) => '$baseUrl/api/v1/viajes/$id/cancelar';

  // Clientes
  static const String clienteSolicitarViaje = '$baseUrl/api/v1/clientes/viajes';
  static const String clienteHistorial = '$baseUrl/api/v1/clientes/viajes';
}
