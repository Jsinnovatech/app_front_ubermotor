import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../conductor/screens/registro_conductor_multipaso.dart';
import '../../cliente/screens/registro_cliente_screen.dart';

/// Seleccion de tipo de cuenta al registrarse: Conductor o Pasajero.
/// (La cuenta de Policía la crea exclusivamente el administrador).
class SeleccionTipoCuentaScreen extends StatelessWidget {
  const SeleccionTipoCuentaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: const Text(
          'Crear cuenta',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '¿Qué tipo de cuenta quieres crear?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'La cuenta de Policía solo la crea el administrador.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.white54),
              ),
              const SizedBox(height: 32),
              // Conductor
              _tarjetaTipo(
                context,
                icono: Icons.two_wheeler,
                titulo: 'Conductor',
                descripcion: 'Quiero manejar y aceptar carreras. Necesito subir mis documentos.',
                color: AppColors.yellow,
                alTocar: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistroConductorMultipaso()),
                ),
              ),
              const SizedBox(height: 16),
              // Pasajero
              _tarjetaTipo(
                context,
                icono: Icons.person,
                titulo: 'Pasajero',
                descripcion: 'Quiero pedir motos para moverme.',
                color: AppColors.green,
                alTocar: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegistroClienteScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tarjetaTipo(
    BuildContext context, {
    required IconData icono,
    required String titulo,
    required String descripcion,
    required Color color,
    required VoidCallback alTocar,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: alTocar,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: Icon(icono, color: AppColors.black, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textDim, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.black),
            ],
          ),
        ),
      ),
    );
  }
}
