/// Sesion activa del usuario: quien esta logueado y su perfil (tipo_usuario).
/// Se persiste en SharedPreferences para sobrevivir a un refresh de pagina.
class SesionActual {
  final String accessToken;
  final int usuarioId;
  final String nombre;
  final String tipoUsuario;

  SesionActual({
    required this.accessToken,
    required this.usuarioId,
    required this.nombre,
    required this.tipoUsuario,
  });

  factory SesionActual.desdeJson(Map<String, dynamic> json) {
    return SesionActual(
      accessToken: json['access_token'],
      usuarioId: json['usuario_id'],
      nombre: json['nombre'],
      tipoUsuario: json['tipo_usuario'],
    );
  }
}
