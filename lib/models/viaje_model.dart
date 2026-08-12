class Viaje {
  final int id;
  final int clienteId;
  final int? conductorId;
  final String estado; // solicitado | asignado | en_curso | completado | cancelado | rechazado
  final double origenLat;
  final double origenLng;
  final double destinoLat;
  final double destinoLng;
  final double tarifa;
  final String metodoPagoCliente;
  final String? origenDireccion;
  final String? destinoDireccion;
  final String? riderNombre;
  final double? riderRating;
  final String? riderFotoUrl;
  final String? conductorNombre;
  final double? conductorRating;
  final String? conductorFotoUrl;
  final String? motoDescripcion;
  final String? motoPlaca;
  final String? motoFotoUrl;

  Viaje({
    required this.id,
    required this.clienteId,
    this.conductorId,
    required this.estado,
    required this.origenLat,
    required this.origenLng,
    required this.destinoLat,
    required this.destinoLng,
    required this.tarifa,
    required this.metodoPagoCliente,
    this.origenDireccion,
    this.destinoDireccion,
    this.riderNombre,
    this.riderRating,
    this.riderFotoUrl,
    this.conductorNombre,
    this.conductorRating,
    this.conductorFotoUrl,
    this.motoDescripcion,
    this.motoPlaca,
    this.motoFotoUrl,
  });

  factory Viaje.desdeJson(Map<String, dynamic> json) {
    return Viaje(
      id: json['id'],
      clienteId: json['cliente_id'],
      conductorId: json['conductor_id'],
      estado: json['estado'],
      origenLat: (json['origen_lat'] as num).toDouble(),
      origenLng: (json['origen_lng'] as num).toDouble(),
      destinoLat: (json['destino_lat'] as num).toDouble(),
      destinoLng: (json['destino_lng'] as num).toDouble(),
      tarifa: (json['tarifa'] as num).toDouble(),
      metodoPagoCliente: json['metodo_pago_cliente'],
      origenDireccion: json['origen_direccion'],
      destinoDireccion: json['destino_direccion'],
      riderNombre: json['rider_nombre'],
      riderRating: (json['rider_rating'] as num?)?.toDouble(),
      riderFotoUrl: json['rider_foto_url'],
      conductorNombre: json['conductor_nombre'],
      conductorRating: (json['conductor_rating'] as num?)?.toDouble(),
      conductorFotoUrl: json['conductor_foto_url'],
      motoDescripcion: json['moto_descripcion'],
      motoPlaca: json['moto_placa'],
      motoFotoUrl: json['moto_foto_url'],
    );
  }
}
