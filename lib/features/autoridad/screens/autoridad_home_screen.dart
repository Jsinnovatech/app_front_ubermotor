import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/autoridad_provider.dart';

/// Pantalla de Serenazgo/Policia: Central SOS epica.
/// - Mapa con pin SOS pulsante (faros), foto del cliente y la moto del conductor.
/// - La moto se mueve en vivo (ubicacion actual cada 3s).
/// - Panel con fotos y datos del involucrado.
class AutoridadHomeScreen extends StatefulWidget {
  final String rol;
  const AutoridadHomeScreen({super.key, required this.rol});

  @override
  State<AutoridadHomeScreen> createState() => _AutoridadHomeScreenState();
}

class _AutoridadHomeScreenState extends State<AutoridadHomeScreen> {
  Timer? _timer;
  Timer? _movimientoTimer;
  AlertaAutoridad? _seleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarTodo();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) _cargarTodo();
      });
    });
  }

  Future<void> _cargarTodo() async {
    final provider = context.read<AutoridadProvider>();
    await provider.cargarAlertas();
    final alerta = _seleccionada ?? (provider.alertas.isNotEmpty ? provider.alertas.first : null);
    if (alerta != null && mounted) {
      provider.cargarUbicacionVivo(alerta.id);
      _movimientoTimer?.cancel();
      _movimientoTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (mounted) context.read<AutoridadProvider>().cargarUbicacionVivo(alerta.id);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _movimientoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutoridadProvider>();
    final alerta = _seleccionada ?? (provider.alertas.isNotEmpty ? provider.alertas.first : null);

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: Text(
          widget.rol == 'policia' ? '🚨 Policía · Central SOS' : '🚨 Serenazgo · Central SOS',
          style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
            icon: const Icon(Icons.logout, color: AppColors.red),
          ),
        ],
      ),
      body: alerta == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.security, color: AppColors.green, size: 56),
                  SizedBox(height: 12),
                  Text(
                    'Sin alertas SOS activas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.white),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Se actualiza automáticamente.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textDim),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                // Mapa épico a pantalla completa: faros, cliente y moto en movimiento
                Positioned.fill(
                  child: _MapaSos(
                    alerta: alerta,
                    motoLat: provider.motoLat,
                    motoLng: provider.motoLng,
                  ),
                ),
                // Panel de datos con fotos en sheet deslizante (estilo InDrive)
                DraggableScrollableSheet(
                  initialChildSize: 0.35,
                  minChildSize: 0.25,
                  maxChildSize: 0.8,
                  snap: true,
                  snapSizes: const [0.35, 0.6],
                  builder: (context, scrollController) {
                    return Container(
                      decoration: const BoxDecoration(
                        color: AppColors.black,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
                      ),
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        children: [
                          Center(
                            child: Container(
                              width: 48,
                              height: 5,
                              decoration: BoxDecoration(color: AppColors.textDim, borderRadius: BorderRadius.circular(999)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _PanelSos(
                            alerta: alerta,
                            onMarcar: () => context.read<AutoridadProvider>().cerrarAlerta(alerta.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}

/// Mapa con el pulso SOS animado (faros), el pin del cliente y la moto del
/// conductor moviendose con su foto.
class _MapaSos extends StatelessWidget {
  final AlertaAutoridad alerta;
  final double? motoLat;
  final double? motoLng;

  const _MapaSos({required this.alerta, this.motoLat, this.motoLng});

  @override
  Widget build(BuildContext context) {
    // Pin de la moto: usa la ubicacion en vivo (si hay) o la de la alerta.
    final motoLatActual = motoLat ?? alerta.contraparteUbicacionLat ?? alerta.ubicacionLat;
    final motoLngActual = motoLng ?? alerta.contraparteUbicacionLng ?? alerta.ubicacionLng;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(alerta.ubicacionLat, alerta.ubicacionLng),
              initialZoom: 14,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jsinnovatech.hablavas',
              ),
              MarkerLayer(
                markers: [
                  // Faro pulsante del SOS (en la posicion del que pide ayuda)
                  Marker(
                    point: LatLng(alerta.ubicacionLat, alerta.ubicacionLng),
                    width: 56,
                    height: 56,
                    child: _FaroSos(esCliente: alerta.origen == 'cliente'),
                  ),
                  // Moto del conductor con foto, en movimiento
                  Marker(
                    point: LatLng(motoLatActual, motoLngActual),
                    width: 52,
                    height: 52,
                    child: _PinMoto(fotoUrl: alerta.motoFotoUrl ?? alerta.contraparteFotoUrl),
                  ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.black.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.red, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                const Text(
                  'SIGUIENDO EN VIVO',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.white, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Faro pulsante (animado) del SOS.
class _FaroSos extends StatefulWidget {
  final bool esCliente;
  const _FaroSos({required this.esCliente});

  @override
  State<_FaroSos> createState() => _FaroSosState();
}

class _FaroSosState extends State<_FaroSos> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulso;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _pulso = Tween(begin: 0.4, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulso,
      builder: (_, __) {
        return Center(
          child: Container(
            width: 40 * _pulso.value,
            height: 40 * _pulso.value,
            decoration: BoxDecoration(
              color: widget.esCliente ? AppColors.blue.withValues(alpha: 0.5) : AppColors.red.withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: (widget.esCliente ? AppColors.blue : AppColors.red).withValues(alpha: 0.6),
                  blurRadius: 12 * _pulso.value,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(Icons.sos, size: 20, color: Colors.white),
          ),
        );
      },
    );
  }
}

/// Pin de la moto del conductor con foto (o icono).
class _PinMoto extends StatelessWidget {
  final String? fotoUrl;
  const _PinMoto({this.fotoUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.green, width: 3),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 6)],
          ),
          child: fotoUrl != null
              ? ClipOval(child: Image.network(fotoUrl!, width: 38, height: 38, fit: BoxFit.cover))
              : const Icon(Icons.sports_motorsports, color: AppColors.green, size: 24),
        ),
      ],
    );
  }
}

/// Panel con las fotos del cliente y la moto, mas los datos.
class _PanelSos extends StatelessWidget {
  final AlertaAutoridad alerta;
  final VoidCallback onMarcar;

  const _PanelSos({required this.alerta, required this.onMarcar});

  @override
  Widget build(BuildContext context) {
    final esCliente = alerta.origen == 'cliente';
    final fotoInvolucrado = alerta.fotoUrl ?? alerta.contraparteFotoUrl;
    final fotoMoto = alerta.motoFotoUrl;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: esCliente ? AppColors.blue : AppColors.red,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SOS #${alerta.id} · ${esCliente ? 'CLIENTE' : 'CONDUCTOR'}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
              const Spacer(),
              const Icon(Icons.gps_fixed, color: AppColors.red, size: 16),
            ],
          ),
          const SizedBox(height: 12),
          // Fotos del involucrado y de la moto
          Row(
            children: [
              _FotoPersona(label: esCliente ? 'Cliente' : 'Conductor', fotoUrl: fotoInvolucrado),
              const SizedBox(width: 12),
              _FotoPersona(label: 'Moto', fotoUrl: fotoMoto, esMoto: true),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alerta.nombre ?? '—',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      alerta.telefono ?? '',
                      style: const TextStyle(fontSize: 13, color: AppColors.textDim, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alerta.moto ?? 'Moto sin registrar',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                    if (alerta.seguro != null)
                      Text(
                        'Seguro: ${alerta.seguro}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (alerta.contraparteNombre != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.gray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(esCliente ? Icons.sports_motorsports : Icons.person, size: 18, color: AppColors.yellow),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${esCliente ? 'Conductor' : 'Cliente'}: ${alerta.contraparteNombre} · ${alerta.contraparteTelefono ?? ''}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.black),
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: Colors.white),
              onPressed: onMarcar,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Marcar como atendida', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _FotoPersona({required String label, String? fotoUrl, bool esMoto = false}) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.yellowSoft,
            shape: BoxShape.circle,
            border: Border.all(color: esMoto ? AppColors.green : AppColors.blue, width: 2),
          ),
          clipBehavior: Clip.antiAlias,
          child: fotoUrl != null
              ? Image.network(fotoUrl, width: 56, height: 56, fit: BoxFit.cover)
              : Icon(esMoto ? Icons.sports_motorsports : Icons.person, color: AppColors.black, size: 28),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.black)),
      ],
    );
  }
}
