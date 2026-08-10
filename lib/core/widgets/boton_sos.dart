import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Boton SOS con confirmacion de 2 presiones (evita falsos positivos).
/// Primera presion arma la alerta, la segunda la dispara.
class BotonSos extends StatefulWidget {
  final Future<void> Function() onDisparar;

  const BotonSos({super.key, required this.onDisparar});

  @override
  State<BotonSos> createState() => _BotonSosState();
}

class _BotonSosState extends State<BotonSos> {
  bool _armado = false;

  Future<void> _presionar() async {
    if (!_armado) {
      setState(() => _armado = true);
      // Si no confirma en 3s, se desarma.
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _armado = false);
      });
      return;
    }
    setState(() => _armado = false);
    await widget.onDisparar();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: FloatingActionButton(
        onPressed: _presionar,
        backgroundColor: _armado ? AppColors.black : AppColors.red,
        foregroundColor: AppColors.white,
        shape: const CircleBorder(),
        child: _armado
            ? const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning, size: 22),
                  SizedBox(height: 2),
                  Text('¿SOS?', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                ],
              )
            : const Icon(Icons.sos, size: 30),
      ),
    );
  }
}
