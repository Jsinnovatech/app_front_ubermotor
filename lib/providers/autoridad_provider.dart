import 'package:flutter/foundation.dart';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Alerta SOS que ven Serenazgo/Policia con todos los datos.
class AlertaAutoridad {
  final int id;
  final String origen;
  final String? nombre;
  final String? telefono;
  final String? email;
  final String? moto;
  final String? seguro;
  final double ubicacionLat;
  final double ubicacionLng;
  final String? contraparteNombre;
  final String? contraparteTelefono;
  final double? contraparteUbicacionLat;
  final double? contraparteUbicacionLng;
  final String estado;

  AlertaAutoridad({
    required this.id,
    required this.origen,
    this.nombre,
    this.telefono,
    this.email,
    this.moto,
    this.seguro,
    required this.ubicacionLat,
    required this.ubicacionLng,
    this.contraparteNombre,
    this.contraparteTelefono,
    this.contraparteUbicacionLat,
    this.contraparteUbicacionLng,
    required this.estado,
  });

  factory AlertaAutoridad.desdeJson(Map<String, dynamic> json) {
    return AlertaAutoridad(
      id: json['id'],
      origen: json['origen'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      moto: json['moto'],
      seguro: json['seguro'],
      ubicacionLat: (json['ubicacion_lat'] as num).toDouble(),
      ubicacionLng: (json['ubicacion_lng'] as num).toDouble(),
      contraparteNombre: json['contraparte_nombre'],
      contraparteTelefono: json['contraparte_telefono'],
      contraparteUbicacionLat: (json['contraparte_ubicacion_lat'] as num?)?.toDouble(),
      contraparteUbicacionLng: (json['contraparte_ubicacion_lng'] as num?)?.toDouble(),
      estado: json['estado'],
    );
  }
}

/// Estado de Serenazgo/Policia: alertas SOS activas con ubicacion en vivo.
class AutoridadProvider extends ChangeNotifier {
  List<AlertaAutoridad> _alertas = [];
  bool _cargando = false;
  String? _error;

  List<AlertaAutoridad> get alertas => _alertas;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarAlertas({String estado = 'activa'}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final data = await ApiClient.get(
        '${ApiConfig.baseUrl}/api/v1/autoridades/alertas?estado=$estado',
      ) as List;
      _alertas = data.map((e) => AlertaAutoridad.desdeJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> cerrarAlerta(int alertaId) async {
    try {
      await ApiClient.post('${ApiConfig.baseUrl}/api/v1/sos/$alertaId/cerrar');
      await cargarAlertas();
    } catch (_) {}
  }
}
