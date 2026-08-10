import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/conductor_provider.dart';
import '../widgets/tarjeta_viaje.dart';
import 'recarga_screen.dart';

/// Home del conductor: disponibilidad, saldo de carreras y viajes disponibles.
/// El saldo es el corazon del negocio: con 0 no se aceptan mas carreras.
class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConductorProvider>().cargarPerfil();
      context.read<ConductorProvider>().cargarPaquetes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ConductorProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('Hola, ${auth.sesion?.nombre ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.cargarViajesDisponibles(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _TarjetaSaldo(provider: provider),
            const SizedBox(height: 16),
            _TarjetaDisponibilidad(provider: provider),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Viajes disponibles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    provider.cargarViajesDisponibles();
                    provider.refrescarSaldo();
                  },
                  child: const Text('Actualizar', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            if (provider.cargando)
              const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
            if (!provider.cargando && provider.viajesDisponibles.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'No hay viajes disponibles ahora.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
                ),
              ),
            ...provider.viajesDisponibles.map(
              (viaje) => TarjetaViaje(
                viaje: viaje,
                onAceptar: () async {
                  try {
                    await provider.aceptar(viaje.id);
                  } catch (e) {
                    _mostrarError(e);
                  }
                },
                onRechazar: () async {
                  try {
                    await provider.rechazar(viaje.id);
                  } catch (e) {
                    _mostrarError(e);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
    );
  }
}

class _TarjetaSaldo extends StatelessWidget {
  final ConductorProvider provider;
  const _TarjetaSaldo({required this.provider});

  @override
  Widget build(BuildContext context) {
    final saldo = provider.saldo;
    final color = saldo <= 0 ? AppColors.red : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Te quedan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDim)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$saldo', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: color)),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('carreras', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black)),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Recargar',
                icon: const Icon(Icons.add_circle, color: AppColors.yellow, size: 32),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecargaScreen()),
                ),
              ),
            ],
          ),
          if (saldo <= 0)
            const Text(
              'Sin saldo para hoy: recarga para seguir aceptando carreras.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.red),
            ),
        ],
      ),
    );
  }
}

class _TarjetaDisponibilidad extends StatelessWidget {
  final ConductorProvider provider;
  const _TarjetaDisponibilidad({required this.provider});

  @override
  Widget build(BuildContext context) {
    final disponible = provider.perfil?.disponible ?? false;
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            value: disponible,
            activeTrackColor: AppColors.green,
            title: const Text('En línea', style: TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              disponible ? 'Aceptando viajes' : 'Offline',
              style: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            onChanged: (v) => provider.cambiarDisponibilidad(disponible: v),
          ),
        ),
      ],
    );
  }
}
