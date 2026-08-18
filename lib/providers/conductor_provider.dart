import 'package:flutter/foundation.dart';
import '../models/conductor_model.dart';
import '../models/paquete_model.dart';
import '../models/viaje_model.dart';
import '../services/conductor_service.dart';
import '../services/viaje_service.dart';

/// Estado del conductor: perfil, disponibilidad, saldo y viajes disponibles.
class ConductorProvider extends ChangeNotifier {
  Conductor? _perfil;
  List<Viaje> _viajesDisponibles = [];
  List<Viaje> _historial = [];
  List<Paquete> _paquetes = [];
  bool _cargando = false;
  String? _error;
  int? _ultimoViajeNuevoId;
  Viaje? _viajeActivo;

  Conductor? get perfil => _perfil;
  List<Viaje> get viajesDisponibles => _viajesDisponibles;
  List<Viaje> get historial => _historial;
  List<Paquete> get paquetes => _paquetes;
  bool get cargando => _cargando;
  String? get error => _error;
  int? get ultimoViajeNuevoId => _ultimoViajeNuevoId;
  Viaje? get viajeActivo => _viajeActivo;

  /// True si aparece un viaje que no estaba antes (para avisar como InDrive).
  bool get hayViajeNuevo => _ultimoViajeNuevoId != null;
  int get saldo => _perfil?.saldoCarreras ?? 0;

  Future<void> cargarViajeActivo() async {
    try {
      _viajeActivo = await ConductorService.viajeActivo();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cargarPerfil() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      _perfil = await ConductorService.perfil();
    } catch (e) {
      _error = e.toString();
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> refrescarSaldo() async {
    try {
      // Recarga el perfil completo (saldo + viajes completados + ingreso del
      // dia) para que las metricas del Home se actualicen al completar un viaje.
      _perfil = await ConductorService.perfil();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cambiarDisponibilidad({required bool disponible}) async {
    _perfil = await ConductorService.cambiarDisponibilidad(disponible: disponible);
    notifyListeners();
  }

  Future<void> cargarViajesDisponibles({double? lat, double? lng, double radioKm = 5}) async {
    try {
      final nuevos = await ViajeService.disponibles(lat: lat, lng: lng, radioKm: radioKm);
      final idsViejos = _viajesDisponibles.map((v) => v.id).toSet();
      final idNuevo = nuevos.where((v) => !idsViejos.contains(v.id)).map((v) => v.id).firstOrNull;
      _viajesDisponibles = nuevos;
      if (idNuevo != null) _ultimoViajeNuevoId = idNuevo;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void consumirViajeNuevo() {
    _ultimoViajeNuevoId = null;
    notifyListeners();
  }

  /// Viaje recibido por WebSocket (push): se agrega al tope si no existe.
  void agregarViajeRealtime(Viaje viaje) {
    if (_viajesDisponibles.any((v) => v.id == viaje.id)) return;
    _viajesDisponibles.insert(0, viaje);
    _ultimoViajeNuevoId = viaje.id;
    notifyListeners();
  }

  Future<void> actualizarUbicacion({required double lat, required double lng}) async {
    try {
      await ConductorService.actualizarUbicacion(lat: lat, lng: lng);
    } catch (_) {}
  }

  Future<void> aceptar(int viajeId) async {
    final viaje = await ViajeService.aceptar(viajeId);
    _viajesDisponibles.removeWhere((v) => v.id == viaje.id);
    await refrescarSaldo();
    notifyListeners();
  }

  Future<void> rechazar(int viajeId) async {
    final viaje = await ViajeService.rechazar(viajeId);
    _viajesDisponibles.removeWhere((v) => v.id == viaje.id);
    await refrescarSaldo();
    notifyListeners();
  }

  Future<Viaje> llegar(int viajeId) async {
    final viaje = await ViajeService.llegar(viajeId);
    _viajeActivo = viaje;
    notifyListeners();
    return viaje;
  }

  Future<Viaje> iniciar(int viajeId) async {
    final viaje = await ViajeService.iniciar(viajeId);
    _viajeActivo = viaje;
    notifyListeners();
    return viaje;
  }

  Future<void> cancelar(int viajeId) async {
    final viaje = await ViajeService.cancelar(viajeId);
    _viajeActivo = null;
    _viajesDisponibles.removeWhere((v) => v.id == viaje.id);
    await refrescarSaldo();
    notifyListeners();
  }

  Future<void> completar(int viajeId) async {
    final viaje = await ViajeService.completar(viajeId);
    _viajeActivo = null;
    _viajesDisponibles.removeWhere((v) => v.id == viaje.id);
    await refrescarSaldo();
    notifyListeners();
  }

  Future<void> cargarPaquetes() async {
    _paquetes = await ConductorService.paquetes();
    notifyListeners();
  }

  Future<void> cargarHistorial() async {
    try {
      _historial = await ConductorService.historial();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> recargar(int paqueteId) async {
    final recarga = await ConductorService.recargar(paqueteId: paqueteId);
    // El pago queda 'pendiente' hasta confirmarse; recien ahi se acredita el
    // saldo del dia (regla de negocio).
    if (recarga['id'] != null) {
      await ConductorService.confirmarRecarga(recarga['id'] as int);
    }
    await refrescarSaldo();
    notifyListeners();
  }
}
