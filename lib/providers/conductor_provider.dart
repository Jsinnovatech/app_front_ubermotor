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
  List<Paquete> _paquetes = [];
  bool _cargando = false;
  String? _error;

  Conductor? get perfil => _perfil;
  List<Viaje> get viajesDisponibles => _viajesDisponibles;
  List<Paquete> get paquetes => _paquetes;
  bool get cargando => _cargando;
  String? get error => _error;
  int get saldo => _perfil?.saldoCarreras ?? 0;

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
      final saldo = await ConductorService.saldo();
      _perfil = _perfil == null
          ? null
          : Conductor(
              id: _perfil!.id,
              nombre: _perfil!.nombre,
              dni: _perfil!.dni,
              ratingPromedio: _perfil!.ratingPromedio,
              viajesCompletados: _perfil!.viajesCompletados,
              disponible: _perfil!.disponible,
              aprobado: _perfil!.aprobado,
              saldoCarreras: saldo,
              saldoFecha: _perfil!.saldoFecha,
            );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> cambiarDisponibilidad({required bool disponible}) async {
    _perfil = await ConductorService.cambiarDisponibilidad(disponible: disponible);
    notifyListeners();
  }

  Future<void> cargarViajesDisponibles() async {
    try {
      _viajesDisponibles = await ViajeService.disponibles();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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

  Future<void> cargarPaquetes() async {
    _paquetes = await ConductorService.paquetes();
    notifyListeners();
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
