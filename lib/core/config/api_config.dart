/// Unica fuente de verdad de URLs del backend. Ningun service adivina rutas.
class ApiConfig {
  static const String baseUrl = 'http://localhost:8000';

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

  // Viajes
  static const String viajesDisponibles = '$baseUrl/api/v1/viajes/disponibles';
  static String viajeAceptar(int id) => '$baseUrl/api/v1/viajes/$id/aceptar';
  static String viajeRechazar(int id) => '$baseUrl/api/v1/viajes/$id/rechazar';
  static String viajeIniciar(int id) => '$baseUrl/api/v1/viajes/$id/iniciar';
  static String viajeCompletar(int id) => '$baseUrl/api/v1/viajes/$id/completar';
  static String viajeCancelar(int id) => '$baseUrl/api/v1/viajes/$id/cancelar';

  // Clientes
  static const String clienteSolicitarViaje = '$baseUrl/api/v1/clientes/viajes';
  static const String clienteHistorial = '$baseUrl/api/v1/clientes/viajes';
}
