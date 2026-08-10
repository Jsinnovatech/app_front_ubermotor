import 'package:flutter/foundation.dart';
import '../models/conductor_disponible_model.dart';
import '../services/cliente_service.dart';

/// Estado del cliente: motos disponibles cerca con su reputacion.
class ClienteProvider extends ChangeNotifier {
  List<ConductorDisponible> _conductores = [];
  bool _cargando = false;
  String? _error;

  List<ConductorDisponible> get conductores => _conductores;
  bool get cargando => _cargando;
  String? get error => _error;

  Future<void> cargarConductores({required double lat, required double lng}) async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _conductores = await ClienteService.conductoresDisponibles(lat: lat, lng: lng);
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }
}
