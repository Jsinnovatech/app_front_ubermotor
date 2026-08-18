import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modo de la app para cuentas de CONDUCTOR que también pueden ser pasajeros
/// (como InDrive): con un switch desde el menú se cambia de "modo conductor"
/// a "modo pasajero". El modo se recuerda entre sesiones.
class ModoAppProvider extends ChangeNotifier {
  static const _key = 'modo_pasajero';
  bool _esPasajero = false;

  bool get esPasajero => _esPasajero;

  ModoAppProvider() {
    _cargar();
  }

  Future<void> _cargar() async {
    final prefs = await SharedPreferences.getInstance();
    _esPasajero = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  Future<void> cambiarModo(bool pasajero) async {
    _esPasajero = pasajero;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, pasajero);
  }
}
