import 'package:geolocator/geolocator.dart';

/// Captura la posicion actual del conductor (GPS/mobile o navegador en web).
/// En web usa navigator.geolocation del navegador (pide permiso).
class UbicacionService {
  /// Pide permiso de ubicacion y devuelve la posicion actual.
  static Future<Position?> obtenerPosicionActual() async {
    try {
      bool servicioActivo = await Geolocator.isLocationServiceEnabled();
      if (!servicioActivo) return null;

      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (_) {
      return null;
    }
  }
}
