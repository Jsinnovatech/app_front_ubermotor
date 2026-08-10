import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/conductor_provider.dart';

/// Pantalla de recarga replicada del diseno de Stitch (MotoRide):
/// cards de paquetes 2/4/8 (el 4 marcado "Recomendado"), boton
/// "Pagar con Yape" y modal de exito con saldo actual y vencimiento.
class RecargaScreen extends StatefulWidget {
  const RecargaScreen({super.key});

  @override
  State<RecargaScreen> createState() => _RecargaScreenState();
}

class _RecargaScreenState extends State<RecargaScreen> {
  int? _paqueteSeleccionado;
  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    context.read<ConductorProvider>().cargarPaquetes();
  }

  Future<void> _pagar(ConductorProvider provider) async {
    if (_paqueteSeleccionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona un paquete')),
      );
      return;
    }
    setState(() => _cargando = true);
    try {
      await provider.recargar(_paqueteSeleccionado!);
      if (!mounted) return;
      final saldo = provider.saldo;
      final paquete = provider.paquetes.firstWhere((p) => p.id == _paqueteSeleccionado);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _ExitoDialog(paqueteNombre: paquete.nombre, paqueteMonto: paquete.monto, paqueteCarreras: paquete.carreras, saldoActual: saldo),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConductorProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recarga tu Saldo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Elige el paquete que mejor se adapte a tu día.',
            style: TextStyle(fontSize: 16, color: AppColors.textDim),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.yellowSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info, size: 16, color: AppColors.black),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Importante: Saldo diario no acumulable. Las carreras no utilizadas se perderán al final del día.',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.black),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...provider.paquetes.map((p) {
            final recomendado = p.carreras == 10;
            final seleccionado = _paqueteSeleccionado == p.id;
            return GestureDetector(
              onTap: () => setState(() => _paqueteSeleccionado = p.id),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: seleccionado ? AppColors.yellowSoft : AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: seleccionado ? AppColors.yellow : AppColors.line,
                    width: seleccionado ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: seleccionado ? AppColors.yellow : AppColors.gray,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(seleccionado ? Icons.check : Icons.two_wheeler, color: AppColors.black, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'S/ ${p.monto}.00',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black),
                          ),
                          Text(
                            '${p.carreras} viajes',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDim),
                          ),
                        ],
                      ),
                    ),
                    if (recomendado)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.black,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Recomendado',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.yellow),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _cargando ? null : () => _pagar(provider),
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(_cargando ? 'Procesando...' : 'Pagar con Yape'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExitoDialog extends StatelessWidget {
  final String paqueteNombre;
  final int paqueteMonto;
  final int paqueteCarreras;
  final int saldoActual;

  const _ExitoDialog({
    required this.paqueteNombre,
    required this.paqueteMonto,
    required this.paqueteCarreras,
    required this.saldoActual,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.green, size: 56),
            const SizedBox(height: 8),
            const Text(
              '¡Recarga Exitosa!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
            ),
            const SizedBox(height: 4),
            Text(
              'Has recargado $paqueteCarreras viajes (S/ $paqueteMonto) mediante Yape.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textDim, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Saldo Actual', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim)),
                  Text('$saldoActual viajes', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black)),
                  const SizedBox(height: 4),
                  const Text('Vencimiento · Hoy, 23:59', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Volver al Inicio'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
