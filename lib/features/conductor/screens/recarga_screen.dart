import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/conductor_provider.dart';

/// Pantalla de recarga: elige un paquete (2/4/8 soles) y compra las carreras.
/// Regla "magica": 10 carreras por 4 soles (0.40/carrera), saldo del dia.
class RecargaScreen extends StatefulWidget {
  const RecargaScreen({super.key});

  @override
  State<RecargaScreen> createState() => _RecargaScreenState();
}

class _RecargaScreenState extends State<RecargaScreen> {
  bool _cargando = false;
  String? _mensaje;

  @override
  void initState() {
    super.initState();
    context.read<ConductorProvider>().cargarPaquetes();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConductorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recargar carreras')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Elige tu paquete',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
          ),
          const SizedBox(height: 4),
          const Text(
            'El saldo es por día: lo que no uses, se pierde al terminar el día.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textDim, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          ...provider.paquetes.map((p) {
            final porCarrera = (p.monto / p.carreras).toStringAsFixed(2);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.yellowSoft,
                  child: const Icon(Icons.savings, color: AppColors.black),
                ),
                title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(
                  'S/ ${p.monto}.00 · ${p.carreras} carreras · S/ $porCarrera c/u',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDim, fontSize: 12.5),
                ),
                trailing: const Icon(Icons.chevron_right, color: AppColors.yellow),
                onTap: _cargando ? null : () => _comprar(provider, p.id),
              ),
            );
          }),
          if (_mensaje != null) ...[
            const SizedBox(height: 8),
            Text(_mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
          ],
        ],
      ),
    );
  }

  Future<void> _comprar(ConductorProvider provider, int paqueteId) async {
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await provider.recargar(paqueteId);
      setState(() => _mensaje = 'Pago registrado. Tu saldo se acreditó para hoy.');
      await provider.refrescarSaldo();
    } catch (e) {
      if (mounted) {
        setState(() => _mensaje = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }
}
