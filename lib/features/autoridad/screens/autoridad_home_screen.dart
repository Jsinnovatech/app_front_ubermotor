import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/autoridad_provider.dart';

/// Pantalla de Serenazgo/Policia: alertas SOS activas con todos los datos
/// del involucrado (cliente/chofer), la moto, el seguro y ubicacion en el
/// mapa. Refresca cada 5s para seguir el movimiento en tiempo real.
class AutoridadHomeScreen extends StatefulWidget {
  final String rol;
  const AutoridadHomeScreen({super.key, required this.rol});

  @override
  State<AutoridadHomeScreen> createState() => _AutoridadHomeScreenState();
}

class _AutoridadHomeScreenState extends State<AutoridadHomeScreen> {
  Timer? _timer;
  AlertaAutoridad? _seleccionada;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AutoridadProvider>().cargarAlertas();
      _timer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted) context.read<AutoridadProvider>().cargarAlertas();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AutoridadProvider>();
    final alerta = _seleccionada ?? (provider.alertas.isNotEmpty ? provider.alertas.first : null);

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.gray,
        elevation: 0,
        title: Text(
          widget.rol == 'policia' ? 'Policía · Central SOS' : 'Serenazgo · Central SOS',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.black),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.black),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Se actualiza automáticamente cada 5 segundos.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textDim),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Mapa con la ubicacion del SOS (y la contraparte si viaja)
                Expanded(
                  flex: 5,
                  child: _MapaAlerta(alerta: alerta),
                ),
                // Datos de la alerta
                Expanded(
                  flex: 5,
                  child: _PanelAlerta(
                    alerta: alerta,
                    onMarcar: () => context.read<AutoridadProvider>().cerrarAlerta(alerta.id),
                    onCambiar: _seleccionada == null
                        ? null
                        : () => setState(() => _seleccionada = null),
                  ),
                ),
              ],
            ),
    );
  }
}

class _MapaAlerta extends StatelessWidget {
  final AlertaAutoridad alerta;
  const _MapaAlerta({required this.alerta});

  @override
  Widget build(BuildContext context) {
    final marcadores = <Marker>[
      Marker(
        point: LatLng(alerta.ubicacionLat, alerta.ubicacionLng),
        width: 40,
        height: 40,
        child: const Icon(Icons.sos, color: AppColors.red, size: 40),
      ),
    ];
    if (alerta.contraparteUbicacionLat != null && alerta.contraparteUbicacionLng != null) {
      marcadores.add(
        Marker(
          point: LatLng(alerta.contraparteUbicacionLat!, alerta.contraparteUbicacionLng!),
          width: 34,
          height: 34,
          child: const Icon(Icons.two_wheeler, color: AppColors.blue, size: 34),
        ),
      );
    }

    return ClipRRect(
      child: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(alerta.ubicacionLat, alerta.ubicacionLng),
          initialZoom: 13,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.jsinnovatech.hablavas',
          ),
          MarkerLayer(markers: marcadores),
        ],
      ),
    );
  }
}

class _PanelAlerta extends StatelessWidget {
  final AlertaAutoridad alerta;
  final VoidCallback onMarcar;
  final VoidCallback? onCambiar;

  const _PanelAlerta({required this.alerta, required this.onMarcar, this.onCambiar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.redSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'SOS #${alerta.id} · ${alerta.origen}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.red),
                ),
              ),
              const Spacer(),
              if (onCambiar != null)
                TextButton(onPressed: onCambiar, child: const Text('Cambiar alerta')),
            ],
          ),
          const SizedBox(height: 10),
          _fila(Icons.person, 'Persona', '${alerta.nombre ?? '—'} · ${alerta.telefono ?? ''}'),
          const SizedBox(height: 6),
          _fila(Icons.directions_bike, 'Moto', alerta.moto ?? '—'),
          const SizedBox(height: 6),
          _fila(Icons.verified_user, 'Seguro', alerta.seguro ?? '—'),
          const SizedBox(height: 6),
          if (alerta.contraparteNombre != null)
            _fila(
              Icons.people,
              'Contraparte',
              '${alerta.contraparteNombre} · ${alerta.contraparteTelefono ?? ''}',
            ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.white),
              onPressed: onMarcar,
              child: const Text('Marcar como atendida', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fila(IconData icono, String label, String valor) {
    return Row(
      children: [
        Icon(icono, size: 18, color: AppColors.yellow),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDim))),
        Expanded(
          child: Text(valor, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.black)),
        ),
      ],
    );
  }
}
