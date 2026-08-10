class Moto {
  final String? marca;
  final String? modelo;
  final String? placa;
  final String? color;

  Moto({this.marca, this.modelo, this.placa, this.color});

  factory Moto.desdeJson(Map<String, dynamic>? json) {
    if (json == null) return Moto();
    return Moto(
      marca: json['marca'],
      modelo: json['modelo'],
      placa: json['placa'],
      color: json['color'],
    );
  }
}

/// Conductor disponible cerca del cliente (con reputacion para decidir).
class ConductorDisponible {
  final int conductorId;
  final String nombre;
  final String? fotoUrl;
  final double ratingPromedio;
  final int viajesCompletados;
  final double ubicacionLat;
  final double ubicacionLng;
  final double distanciaKm;
  final Moto moto;

  ConductorDisponible({
    required this.conductorId,
    required this.nombre,
    this.fotoUrl,
    required this.ratingPromedio,
    required this.viajesCompletados,
    required this.ubicacionLat,
    required this.ubicacionLng,
    required this.distanciaKm,
    required this.moto,
  });

  factory ConductorDisponible.desdeJson(Map<String, dynamic> json) {
    return ConductorDisponible(
      conductorId: json['conductor_id'],
      nombre: json['nombre'],
      fotoUrl: json['foto_url'],
      ratingPromedio: (json['rating_promedio'] as num).toDouble(),
      viajesCompletados: json['viajes_completados'] ?? 0,
      ubicacionLat: (json['ubicacion_lat'] as num).toDouble(),
      ubicacionLng: (json['ubicacion_lng'] as num).toDouble(),
      distanciaKm: (json['distancia_km'] as num).toDouble(),
      moto: Moto.desdeJson(json['moto'] as Map<String, dynamic>?),
    );
  }
}
