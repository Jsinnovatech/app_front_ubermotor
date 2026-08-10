class Conductor {
  final int id;
  final String nombre;
  final String? dni;
  final String? dniFotoUrl;
  final String? licencia;
  final String? licenciaFotoUrl;
  final String? fotoUrl;
  final String? antecedentesFotoUrl;
  final bool? antecedentesValido;
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
    this.dniFotoUrl,
    this.licencia,
    this.licenciaFotoUrl,
    this.fotoUrl,
    this.antecedentesFotoUrl,
    this.antecedentesValido,
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
      dniFotoUrl: json['dni_foto_url'],
      licencia: json['licencia'],
      licenciaFotoUrl: json['licencia_foto_url'],
      fotoUrl: json['foto_url'],
      antecedentesFotoUrl: json['antecedentes_foto_url'],
      antecedentesValido: json['antecedentes_valido'],
      ratingPromedio: (json['rating_promedio'] as num?)?.toDouble() ?? 5.0,
      viajesCompletados: json['viajes_completados'] ?? 0,
      disponible: json['disponible'] ?? false,
      aprobado: json['aprobado'] ?? false,
      saldoCarreras: json['saldo_carreras'] ?? 0,
      saldoFecha: json['saldo_fecha'],
    );
  }
}
