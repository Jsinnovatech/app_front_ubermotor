import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/conductor_provider.dart';
import 'registro_documentos_screen.dart';

/// Pantalla del conductor NO aprobado: muestra que esta en validacion o que
/// debe completar sus documentos. Solo cuando el admin lo aprueba puede operar.
class ValidacionPendienteScreen extends StatefulWidget {
  const ValidacionPendienteScreen({super.key});

  @override
  State<ValidacionPendienteScreen> createState() => _ValidacionPendienteScreenState();
}

class _ValidacionPendienteScreenState extends State<ValidacionPendienteScreen> {
  bool _cargando = false;

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    await context.read<ConductorProvider>().cargarPerfil();
    if (mounted) setState(() => _cargando = false);
  }

  @override
  Widget build(BuildContext context) {
    final conductor = context.watch<ConductorProvider>().perfil;
    final tieneDocumentos = conductor != null && (conductor.dniFotoUrl != null || conductor.dni != null);

    return Scaffold(
      backgroundColor: AppColors.gray,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top, size: 52, color: AppColors.yellow),
              ),
              const SizedBox(height: 24),
              const Text(
                'Cuenta en validación',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              const SizedBox(height: 10),
              const Text(
                'Un administrador está revisando tus documentos.\n'
                'Podrás aceptar carreras apenas te aprobemos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 28),
              if (conductor != null && !(conductor.dniFotoUrl != null || conductor.dni != null)) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.yellow,
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegistroDocumentosScreen()),
                    ),
                    icon: const Icon(Icons.badge),
                    label: const Text('SUBIR MIS DOCUMENTOS', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _cargando ? null : _cargarPerfil,
                icon: const Icon(Icons.refresh),
                label: Text(_cargando ? 'Revisando...' : 'Ya me validaron — Revisar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
