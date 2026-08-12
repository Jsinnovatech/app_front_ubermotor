/// Perfil del cliente: lo que ve en la pestana Cuenta.
class ClientePerfil {
  final int id;
  final String nombre;
  final String? email;
  final String? fotoUrl;
  final int viajesRealizados;
  final double ratingPromedio;

  ClientePerfil({
    required this.id,
    required this.nombre,
    this.email,
    this.fotoUrl,
    this.viajesRealizados = 0,
    this.ratingPromedio = 5.0,
  });

  factory ClientePerfil.desdeJson(Map<String, dynamic> json) {
    return ClientePerfil(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      email: json['email'],
      fotoUrl: json['foto_url'],
      viajesRealizados: (json['viajes_realizados'] as num?)?.toInt() ?? 0,
      ratingPromedio: (json['rating_promedio'] as num?)?.toDouble() ?? 5.0,
    );
  }
}
