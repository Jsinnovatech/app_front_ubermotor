import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'campo_oferta.dart';

/// Dialogo para que el conductor escriba su oferta sobre una carrera disponible
/// (flujo InDrive). Devuelve el precio ofertado o null si cancela.
Future<double?> pedirOferta(BuildContext context, {double inicial = 3.0}) {
  return showDialog<double>(
    context: context,
    builder: (_) => const DialogoOferta(),
  );
}

class DialogoOferta extends StatefulWidget {
  const DialogoOferta({super.key});

  @override
  State<DialogoOferta> createState() => _DialogoOfertaState();
}

class _DialogoOfertaState extends State<DialogoOferta> {
  double _precio = 3.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Oferta tu precio', style: TextStyle(fontWeight: FontWeight.w900)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'El conductor no consume saldo por ofertar; solo se descuenta cuando el cliente acepta tu propuesta.',
            style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          CampoOferta(onCambio: (v) => _precio = v),
          const SizedBox(height: 6),
          const Text(
            'Mínimo S/ 3.00 · máximo S/ 50.00',
            style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
          ),
          onPressed: () => Navigator.of(context).pop(_precio),
          child: Text(
            'Ofertar S/ ${_precio.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}
