import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/conductor_provider.dart';

/// Pantalla del conductor NO aprobado: su cuenta esta en validacion. Si el
/// admin tarda, se contacta soporte por WhatsApp. Ya no abre la grilla de
/// documentos (el conductor los sube en el multipaso al registrarse).
class ValidacionPendienteScreen extends StatefulWidget {
  const ValidacionPendienteScreen({super.key});

  @override
  State<ValidacionPendienteScreen> createState() => _ValidacionPendienteScreenState();
}

class _ValidacionPendienteScreenState extends State<ValidacionPendienteScreen> {
  static const _whatsapp = '51932259291'; // soporte HablaVas

  bool _cargando = false;

  Future<void> _cargarPerfil() async {
    setState(() => _cargando = true);
    await context.read<ConductorProvider>().cargarPerfil();
    if (mounted) setState(() => _cargando = false);
  }

  Future<void> _contactarWhatsApp() async {
    final uri = Uri.parse('https://wa.me/$_whatsapp');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Soporte: si el admin tarda en validar, contactar por WhatsApp
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Aún no validan tus documentos',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Si ya pasó tiempo y sigue sin validarse, escríbenos por WhatsApp.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textDim),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _contactarWhatsApp,
                        icon: const Icon(Icons.chat),
                        label: const Text('Soporte por WhatsApp', style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
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
