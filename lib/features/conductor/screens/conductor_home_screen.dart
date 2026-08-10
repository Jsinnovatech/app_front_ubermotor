import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/conductor_provider.dart';
import 'recarga_screen.dart';

/// Home del conductor replicado del diseno de Stitch (MotoRide):
/// header UberMoto, toggle Disponible, badge "Objetivo Diario" (saldo),
/// "Balance de Hoy" con pill "No acumulable", y bottom nav.
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
    final disponible = provider.perfil?.disponible ?? false;
    final saldo = provider.saldo;

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.gray,
        elevation: 0,
        leadingWidth: 90,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: const [
              Icon(Icons.two_wheeler, color: AppColors.yellow, size: 26),
              SizedBox(width: 6),
              Text(
                'UberMoto',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.yellow),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: IconButton(
              tooltip: 'Salir',
              onPressed: () => context.read<AuthProvider>().cerrarSesion(),
              icon: const Icon(Icons.logout, color: AppColors.yellow),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Toggle Disponible
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line, width: 1),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            disponible ? 'Disponible' : 'Offline',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.black),
                          ),
                          Text(
                            disponible ? 'Buscando viajes cercanos...' : 'Activa el modo para recibir viajes',
                            style: const TextStyle(fontSize: 16, color: AppColors.textDim),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: disponible,
                      activeTrackColor: AppColors.yellow,
                      activeThumbColor: AppColors.white,
                      onChanged: (v) => provider.cambiarDisponibilidad(disponible: v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Badge Objetivo Diario (saldo)
              InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecargaScreen()),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.speed, color: AppColors.black, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'OBJETIVO DIARIO',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.black),
                            ),
                            Text(
                              'Te quedan $saldo carreras',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.black),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.add_circle, color: AppColors.black),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Balance de Hoy
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line, width: 1),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'BALANCE DE HOY',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppColors.textDim),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.gray,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.info, size: 14, color: AppColors.textDim),
                              SizedBox(width: 4),
                              Text(
                                'No acumulable',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'S/ 0.00',
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _metricaMini('Viajes', '${provider.perfil?.viajesCompletados ?? 0}'),
                        const SizedBox(width: 12),
                        _metricaMini('Saldo', '$saldo'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: provider.viajesDisponibles.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay viajes disponibles ahora.\nBaja a actualizar.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.viajesDisponibles.length,
                        itemBuilder: (_, i) => _filaViaje(provider, i),
                      ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    provider.cargarViajesDisponibles();
                    provider.refrescarSaldo();
                  },
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Actualizar viajes'),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _BottomNav(provider: provider),
    );
  }

  Widget _metricaMini(String label, String valor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(valor, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _filaViaje(ConductorProvider provider, int index) {
    final viaje = provider.viajesDisponibles[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.place, color: AppColors.green, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  viaje.origenDireccion ?? 'Origen (${viaje.origenLat.toStringAsFixed(4)})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.sports_motorsports, color: AppColors.blue, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  viaje.destinoDireccion ?? 'Destino (${viaje.destinoLat.toStringAsFixed(4)})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'S/ ${viaje.tarifa.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              const Spacer(),
              Text(
                viaje.metodoPagoCliente,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDim),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.white),
                    onPressed: () => provider.aceptar(viaje.id).catchError((e) => _mostrarError(e)),
                    child: const Text('Aceptar'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.red,
                      side: const BorderSide(color: AppColors.red, width: 1.5),
                    ),
                    onPressed: () => provider.rechazar(viaje.id).catchError((e) => _mostrarError(e)),
                    child: const Text('Rechazar'),
                  ),
                ),
              ),
            ],
          ),
        ],
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

class _BottomNav extends StatelessWidget {
  final ConductorProvider provider;
  const _BottomNav({required this.provider});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home, 'Home', true),
      (Icons.two_wheeler, 'Rides', false),
      (Icons.account_balance_wallet, 'Wallet', false),
      (Icons.person, 'Account', false),
    ];
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: items.map((item) {
          final (icono, label, activo) = item;
          return Expanded(
            child: InkWell(
              onTap: () {
                if (label == 'Wallet') {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecargaScreen()));
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono,
                      size: 24,
                      color: activo ? AppColors.yellow : AppColors.textDim,
                      fill: activo ? 1 : 0),
                  const SizedBox(height: 2),
                  Text(label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: activo ? FontWeight.w800 : FontWeight.w600,
                        color: activo ? AppColors.yellow : AppColors.textDim,
                      )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
