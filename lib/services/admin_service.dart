import 'dart:typed_data';
import '../core/config/api_config.dart';
import '../core/network/api_client.dart';

/// Operaciones del admin sobre conductores (fotos, aprobacion).
class AdminService {
  static Future<List<Map<String, dynamic>>> conductores() async {
    final data = await ApiClient.get('${ApiConfig.baseUrl}/api/v1/admin/conductores') as List;
    return data.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>> aprobarConductor(int conductorId, {bool aprobado = true}) async {
    final data = await ApiClient.post(
      '${ApiConfig.baseUrl}/api/v1/admin/conductores/$conductorId/aprobar?aprobado=$aprobado',
    );
    return data as Map<String, dynamic>;
  }

  static Future<List<dynamic>> documentosConductor(int conductorId) async {
    final data = await ApiClient.get('${ApiConfig.baseUrl}/api/v1/admin/conductores/$conductorId/documentos');
    return data as List;
  }

  static Future<void> cargarFoto(int conductorId, {required String campo, required Uint8List bytes, required String nombre}) async {
    final url = campo == 'moto'
        ? '${ApiConfig.baseUrl}/api/v1/admin/conductores/$conductorId/moto-foto'
        : '${ApiConfig.baseUrl}/api/v1/admin/conductores/$conductorId/foto';
    await ApiClient.postFile(url, campo: 'archivo', bytes: bytes, nombreArchivo: nombre, query: {});
  }
}
