class Conductor {
  final int id;
  final String nombre;
  final String? dni;
  final double ratingPromedio;
  final int viajesCompletados;
  final bool disponible;
  final bool aprobado;
  final int saldoCarreras;
  final String? saldoFecha;

  Conductor({
    required this.id,
    required this.nombre,
    this.dni,
    required this.ratingPromedio,
    required this.viajesCompletados,
    required this.disponible,
    required this.aprobado,
    required this.saldoCarreras,
    this.saldoFecha,
  });

  factory Conductor.desdeJson(Map<String, dynamic> json) {
    return Conductor(
      id: json['id'],
      nombre: json['nombre'],
      dni: json['dni'],
      ratingPromedio: (json['rating_promedio'] as num?)?.toDouble() ?? 5.0,
      viajesCompletados: json['viajes_completados'] ?? 0,
      disponible: json['disponible'] ?? false,
      aprobado: json['aprobado'] ?? false,
      saldoCarreras: json['saldo_carreras'] ?? 0,
      saldoFecha: json['saldo_fecha'],
    );
  }
}
