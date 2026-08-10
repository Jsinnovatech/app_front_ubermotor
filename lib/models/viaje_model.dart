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
    );
  }
}
