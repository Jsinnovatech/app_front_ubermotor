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
  final String? fotoUrl;
  final String? moto;
  final String? motoFotoUrl;
  final String? seguro;
  final double ubicacionLat;
  final double ubicacionLng;
  final String? contraparteNombre;
  final String? contraparteTelefono;
  final String? contraparteFotoUrl;
  final double? contraparteUbicacionLat;
  final double? contraparteUbicacionLng;
  final String estado;
  final int? viajeId;

  AlertaAutoridad({
    required this.id,
    required this.origen,
    this.nombre,
    this.telefono,
    this.email,
    this.fotoUrl,
    this.moto,
    this.motoFotoUrl,
    this.seguro,
    required this.ubicacionLat,
    required this.ubicacionLng,
    this.contraparteNombre,
    this.contraparteTelefono,
    this.contraparteFotoUrl,
    this.contraparteUbicacionLat,
    this.contraparteUbicacionLng,
    required this.estado,
    this.viajeId,
  });

  factory AlertaAutoridad.desdeJson(Map<String, dynamic> json) {
    return AlertaAutoridad(
      id: json['id'],
      origen: json['origen'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      fotoUrl: json['foto_url'],
      moto: json['moto'],
      motoFotoUrl: json['moto_foto_url'],
      seguro: json['seguro'],
      ubicacionLat: (json['ubicacion_lat'] as num).toDouble(),
      ubicacionLng: (json['ubicacion_lng'] as num).toDouble(),
      contraparteNombre: json['contraparte_nombre'],
      contraparteTelefono: json['contraparte_telefono'],
      contraparteFotoUrl: json['contraparte_foto_url'],
      contraparteUbicacionLat: (json['contraparte_ubicacion_lat'] as num?)?.toDouble(),
      contraparteUbicacionLng: (json['contraparte_ubicacion_lng'] as num?)?.toDouble(),
      estado: json['estado'],
      viajeId: json['viaje_id'],
    );
  }
}

/// Estado de Serenazgo/Policia: alertas SOS activas con ubicacion en vivo.
class AutoridadProvider extends ChangeNotifier {
  List<AlertaAutoridad> _alertas = [];
  bool _cargando = false;
  String? _error;
  double? _motoLat;
  double? _motoLng;

  List<AlertaAutoridad> get alertas => _alertas;
  bool get cargando => _cargando;
  String? get error => _error;
  double? get motoLat => _motoLat;
  double? get motoLng => _motoLng;

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

  /// Ubicacion en vivo de la moto (se llama cada 3s para seguir el movimiento).
  Future<void> cargarUbicacionVivo(int alertaId) async {
    try {
      final data = await ApiClient.get(
        '${ApiConfig.baseUrl}/api/v1/autoridades/alertas/$alertaId/ubicacion-vivo',
      ) as Map<String, dynamic>;
      _motoLat = (data['lat'] as num).toDouble();
      _motoLng = (data['lng'] as num).toDouble();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cerrarAlerta(int alertaId) async {
    try {
      await ApiClient.post('${ApiConfig.baseUrl}/api/v1/sos/$alertaId/cerrar');
      _motoLat = null;
      _motoLng = null;
      await cargarAlertas();
    } catch (_) {}
  }
}
