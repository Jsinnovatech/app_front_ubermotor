import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/boton_sos.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/conductor_provider.dart';
import '../../../providers/modo_app_provider.dart';
import '../../../models/viaje_model.dart';
import '../../../services/ubicacion_service.dart';
import '../../../services/conductor_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/sos_service.dart';
import '../../../services/viaje_service.dart';
import '../widgets/mapa_viajes.dart';
import '../widgets/panel_carrera_nueva.dart';
import 'historial_viajes_screen.dart';
import 'perfil_screen.dart';
import 'recarga_screen.dart';

/// Home del conductor replicado del diseno de Stitch (MotoRide):
/// header HablaVas, toggle Disponible, badge "Objetivo Diario" (saldo),
/// "Balance de Hoy" con pill "No acumulable", y bottom nav.
class ConductorHomeScreen extends StatefulWidget {
  const ConductorHomeScreen({super.key});

  @override
  State<ConductorHomeScreen> createState() => _ConductorHomeScreenState();
}

class _ConductorHomeScreenState extends State<ConductorHomeScreen> {
  Timer? _pollingTimer;
  double? _miLat;
  double? _miLng;
  Viaje? _carreraPendiente;
  List<LatLng> _rutaActiva = [];
  final _realtime = RealtimeService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConductorProvider>().cargarPerfil();
      context.read<ConductorProvider>().cargarPaquetes();
      _conectarWebSocket();
      _iniciarLoopDeUbicacion();
      _revisarViajeActivo();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _realtime.desconectar();
    super.dispose();
  }

  /// Fase 2: WebSocket - los viajes nuevos llegan al instante (push InDrive).
  void _conectarWebSocket() {
    _realtime.onViajeNuevo = (datos) {
      if (!mounted) return;
      if (datos['id'] == null && datos['viaje_id'] == null) return;
      if (datos['id'] == null && datos['viaje_id'] != null) {
        datos['id'] = datos['viaje_id'];
      }
      final provider = context.read<ConductorProvider>();
      final viaje = Viaje.desdeJson(datos);
      provider.agregarViajeRealtime(viaje);
      _mostrarCarreraNueva(viaje);
    };
    _realtime.conectar();
  }

  /// Fase 1: loop cada 5s (fallback). El push por WebSocket es el camino rapido.
  Future<void> _iniciarLoopDeUbicacion() async {
    await _actualizarPosicionYViajes();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _actualizarPosicionYViajes();
    });
  }

  Future<void> _actualizarPosicionYViajes() async {
    final provider = context.read<ConductorProvider>();
    final posicion = await UbicacionService.obtenerPosicionActual();
    if (posicion != null) {
      setState(() {
        _miLat = posicion.latitude;
        _miLng = posicion.longitude;
      });
      provider.actualizarUbicacion(lat: posicion.latitude, lng: posicion.longitude);
      provider.cargarViajesDisponibles(lat: posicion.latitude, lng: posicion.longitude, radioKm: 5);
    } else {
      // Sin permiso de ubicacion: cae a ver todos (comportamiento previo).
      provider.cargarViajesDisponibles();
    }
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
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Menú',
                icon: const Icon(Icons.menu, color: AppColors.black, size: 28),
                onPressed: () => _abrirMenu(),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.two_wheeler, color: AppColors.black, size: 26),
              const SizedBox(width: 4),
              const Text(
                'HablaVas',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: AppColors.black,
                  shadows: [
                    Shadow(color: AppColors.yellow, offset: Offset(-1, -1)),
                    Shadow(color: AppColors.yellow, offset: Offset(1, -1)),
                    Shadow(color: AppColors.yellow, offset: Offset(-1, 1)),
                    Shadow(color: AppColors.yellow, offset: Offset(1, 1)),
                    Shadow(color: AppColors.yellow, offset: Offset(0, 2), blurRadius: 1),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Foto del conductor en el header (igual que el cliente)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _abrirMenu,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.yellow,
                backgroundImage: provider.perfil?.fotoUrl != null
                    ? NetworkImage(provider.perfil!.fotoUrl!)
                    : null,
                child: provider.perfil?.fotoUrl == null
                    ? const Icon(Icons.person, size: 22, color: AppColors.black)
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa a pantalla completa detras del sheet (estilo InDrive)
          Positioned.fill(
            child: MapaViajes(
              viajes: provider.viajesDisponibles,
              latConductor: _miLat,
              lngConductor: _miLng,
              radioKm: 5,
              ruta: _rutaActiva,
              onViajeTap: (viaje) => _mostrarDetalleViaje(viaje),
            ),
          ),
          // Panel deslizante con metricas, toggle, carrera y lista de viajes
          DraggableScrollableSheet(
            initialChildSize: 0.45,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.45, 0.9],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    // Manija de arrastre
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Fila superior: Tus viajes | Tu saldo | Tu ingreso
                    Row(
                      children: [
                        _metricaHome(
                          label: 'Tus viajes',
                          valor: '${provider.perfil?.viajesCompletados ?? 0}',
                          icono: Icons.route,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HistorialViajesScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _metricaHome(
                          label: 'Tu saldo',
                          valor: '$saldo',
                          icono: Icons.speed,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RecargaScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _metricaHome(
                          label: 'Tu ingreso',
                          valor: 'S/ ${(provider.perfil?.ingresoHoy ?? 0).toStringAsFixed(2)}',
                          icono: Icons.payments,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RecargaScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Toggle Disponible delgado y estetico
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line, width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: disponible ? AppColors.green : AppColors.textDim,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              disponible ? 'Disponible · buscando viajes' : 'Offline · activa para recibir viajes',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: disponible ? AppColors.black : AppColors.textDim,
                              ),
                            ),
                          ),
                          Switch(
                            value: disponible,
                            activeTrackColor: AppColors.yellow,
                            activeThumbColor: AppColors.white,
                            inactiveThumbColor: AppColors.textDim,
                            onChanged: (v) => provider.cambiarDisponibilidad(disponible: v),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Card de carrera activa: cuando hay viaje en curso, es el foco
                    if (provider.viajeActivo != null) ...[
                      _CardViajeActivo(
                        viaje: provider.viajeActivo!,
                        onCambio: () async {
                          await context.read<ConductorProvider>().cargarViajeActivo();
                          // Al completar/cancelar el viaje se limpia la ruta
                          // del mapa (antes quedaba marcada).
                          if (mounted) setState(() => _rutaActiva = []);
                        },
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Lista de viajes disponibles: solo cuando no hay carrera activa
                    if (provider.viajeActivo == null) ...[
                      if (provider.viajesDisponibles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: Text(
                              'No hay viajes disponibles ahora. Arrastra para actualizar.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                      else
                        ...provider.viajesDisponibles.map((v) => _filaViaje(provider, v)),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          onPressed: _actualizarPosicionYViajes,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Actualizar viajes'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          // Panel de nueva carrera (via WebSocket)
          if (_carreraPendiente != null)
            Positioned(
              left: 0,
              right: 0,
              top: 12,
              child: PanelCarreraNueva(
                viaje: _carreraPendiente!,
                onAceptar: () => _aceptarCarrera(_carreraPendiente!),
                onRechazar: () => _rechazarCarrera(_carreraPendiente!),
              ),
            ),
        ],
      ),
      floatingActionButton: BotonSos(
        onDisparar: _dispararSos,
      ),
      bottomNavigationBar: _BottomNav(provider: provider),
    );
  }

  void _mostrarCarreraNueva(Viaje viaje) {
    if (!mounted) return;
    setState(() => _carreraPendiente = viaje);
  }

  /// Menu hamburguesa estilo InDrive: perfil del conductor, opciones y el
  /// switch de "modo pasajero" al final (la misma cuenta puede pedir carreras).
  void _abrirMenu() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final provider = context.read<ConductorProvider>();
        final conductor = provider.perfil;
        final modoPasajero = context.watch<ModoAppProvider>().esPasajero;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Perfil: foto grande centrada + nombre debajo
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.yellow,
                        backgroundImage:
                            conductor?.fotoUrl != null ? NetworkImage(conductor!.fotoUrl!) : null,
                        child: conductor?.fotoUrl == null
                            ? const Icon(Icons.person, size: 44, color: AppColors.black)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        conductor?.nombre ?? 'Conductor',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        conductor?.aprobado == true ? 'Cuenta aprobada' : 'En validación',
                        style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.line),
                _opcionMenu(Icons.route, 'Mis viajes', () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistorialViajesScreen()));
                }),
                _opcionMenu(Icons.account_balance_wallet, 'Mi saldo', () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecargaScreen()));
                }),
                _opcionMenu(Icons.person, 'Mi perfil', () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerfilScreen()));
                }),
                _opcionMenu(Icons.logout, 'Cerrar sesión', () {
                  Navigator.of(ctx).pop();
                  context.read<AuthProvider>().cerrarSesion();
                }),
                const Divider(color: AppColors.line),
                const SizedBox(height: 8),
                // Switch: cambiar a modo pasajero (como InDrive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.gray,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_pin, color: AppColors.yellow, size: 24),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Modo pasajero',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.black)),
                            Text('Pide carreras con la misma cuenta',
                                style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                          ],
                        ),
                      ),
                      Switch(
                        value: modoPasajero,
                        activeTrackColor: AppColors.yellow,
                        onChanged: (v) async {
                          Navigator.of(ctx).pop();
                          final modoApp = context.read<ModoAppProvider>();
                          if (v) {
                            // Crea el perfil de pasajero en el backend (si no existe)
                            try {
                              await ConductorService.activarModoPasajero();
                            } catch (_) {}
                          }
                          await modoApp.cambiarModo(v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _opcionMenu(IconData icono, String texto, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icono, color: AppColors.black),
      title: Text(texto, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
      onTap: onTap,
    );
  }

  /// Si el conductor ya tiene una carrera activa (recargó la app en medio de
  /// un viaje, o el WS no estaba conectado), carga el card de carrera activa.
  Future<void> _revisarViajeActivo() async {
    final provider = context.read<ConductorProvider>();
    await provider.cargarViajeActivo();
    await _cargarRutaActiva();
  }

  /// Carga la ruta origen->destino del viaje activo (linea por calles).
  Future<void> _cargarRutaActiva() async {
    final activo = context.read<ConductorProvider>().viajeActivo;
    if (activo == null) {
      if (mounted) setState(() => _rutaActiva = []);
      return;
    }
    try {
      final puntos = await ViajeService.ruta(activo.id);
      if (!mounted) return;
      setState(() {
        _rutaActiva = puntos
            .map((p) => LatLng(p['lat']!, p['lng']!))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _aceptarCarrera(Viaje viaje) async {
    if (!mounted) return;
    setState(() => _carreraPendiente = null);
    try {
      await context.read<ConductorProvider>().aceptar(viaje.id);
      if (!mounted) return;
      await context.read<ConductorProvider>().cargarViajeActivo();
      await _cargarRutaActiva();
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e);
    }
  }

  Future<void> _rechazarCarrera(Viaje viaje) async {
    if (!mounted) return;
    setState(() => _carreraPendiente = null);
    try {
      await context.read<ConductorProvider>().rechazar(viaje.id);
    } catch (_) {}
  }

  Future<void> _dispararSos() async {
    if (!mounted) return;
    final posicion = await UbicacionService.obtenerPosicionActual();
    final lat = posicion?.latitude ?? _miLat ?? -12.0464;
    final lng = posicion?.longitude ?? _miLng ?? -77.0428;
    try {
      await SosService.activar(lat: lat, lng: lng);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.red,
          content: Text('Alerta SOS enviada a Serenazgo/Policía', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    } catch (e) {
      if (mounted) _mostrarError(e);
    }
  }

  /// Abre el detalle de un viaje tocado en el mapa, con boton Aceptar.
  Future<void> _mostrarDetalleViaje(Viaje viaje) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Carrera disponible', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _filaDetalle(Icons.place, viaje.origenDireccion ?? 'Origen'),
            const SizedBox(height: 6),
            _filaDetalle(Icons.sports_motorsports, viaje.destinoDireccion ?? 'Destino'),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(viaje.riderFotoUrl != null ? Icons.person : Icons.person, size: 16, color: AppColors.yellow),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Rider: ${viaje.riderNombre ?? 'Cliente'} · ⭐ ${viaje.riderRating?.toStringAsFixed(1) ?? '—'}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'S/ ${viaje.tarifa.toStringAsFixed(2)} · ${viaje.metodoPagoCliente}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.green, foregroundColor: AppColors.white),
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                await context.read<ConductorProvider>().aceptar(viaje.id);
                if (mounted) {
                  await context.read<ConductorProvider>().cargarViajeActivo();
                }
              } catch (e) {
                if (mounted) _mostrarError(e);
              }
            },
            child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _filaDetalle(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 16, color: AppColors.yellow),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.black),
          ),
        ),
      ],
    );
  }

  Widget _metricaHome({
    required String label,
    required String valor,
    required IconData icono,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line, width: 1),
          ),
          child: Column(
            children: [
              Icon(icono, size: 20, color: AppColors.yellow),
              const SizedBox(height: 4),
              Text(
                valor,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.black),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filaViaje(ConductorProvider provider, Viaje viaje) {
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
                    onPressed: () async {
                      try {
                        await provider.aceptar(viaje.id);
                        if (mounted) {
                          await context.read<ConductorProvider>().cargarViajeActivo();
                        }
                      } catch (e) {
                        if (mounted) _mostrarError(e);
                      }
                    },
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
                switch (label) {
                  case 'Wallet':
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RecargaScreen()));
                  case 'Rides':
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistorialViajesScreen()));
                  case 'Account':
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PerfilScreen()));
                  default:
                    break;
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

/// Card del viaje activo del conductor, visible SOLO cuando hay una carrera
/// en curso. Muestra el boton segun el estado y se refresca solo.
class _CardViajeActivo extends StatefulWidget {
  final Viaje viaje;
  final VoidCallback onCambio;
  const _CardViajeActivo({required this.viaje, required this.onCambio});

  @override
  State<_CardViajeActivo> createState() => _CardViajeActivoState();
}

class _CardViajeActivoState extends State<_CardViajeActivo> {
  late Viaje _viaje;
  bool _trabajando = false;

  @override
  void initState() {
    super.initState();
    _viaje = widget.viaje;
  }

  @override
  Widget build(BuildContext context) {
    final v = _viaje;
    final estado = v.estado;

    final (titulo, color) = switch (estado) {
      'asignado' => ('En camino al cliente', AppColors.blue),
      'llegado' => ('Esperando al cliente', AppColors.yellow),
      'en_curso' => ('En viaje al destino', AppColors.green),
      _ => ('Carrera activa', AppColors.black),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.two_wheeler, size: 20, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
              ),
              if (_trabajando)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.yellow),
                ),
            ],
          ),
          const SizedBox(height: 6),
          _fila(Icons.place, v.origenDireccion ?? 'Origen'),
          const SizedBox(height: 2),
          _fila(Icons.sports_motorsports, v.destinoDireccion ?? 'Destino'),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _trabajando ? null : _accion,
              child: Text(
                switch (estado) {
                  'asignado' => 'LLEGUÉ AL PUNTO',
                  'llegado' => 'INICIAR VIAJE',
                  'en_curso' => 'COMPLETAR VIAJE',
                  _ => 'VER CARRERA',
                },
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
          if (estado == 'asignado' || estado == 'llegado') ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppColors.red),
                  ),
                ),
                onPressed: _trabajando ? null : _confirmarCancelar,
                child: const Text('CANCELAR CARRERA', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _accion() async {
    final provider = context.read<ConductorProvider>();
    setState(() => _trabajando = true);
    try {
      switch (_viaje.estado) {
        case 'asignado':
          final v = await provider.llegar(_viaje.id);
          if (mounted) setState(() => _viaje = v);
        case 'llegado':
          final v = await provider.iniciar(_viaje.id);
          if (mounted) setState(() => _viaje = v);
        case 'en_curso':
          await provider.completar(_viaje.id);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Viaje completado. ¡Gracias!')),
          );
          widget.onCambio();
        default:
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _confirmarCancelar() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar carrera', style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
          _viaje.estado == 'asignado'
              ? 'Si cancelas ahora, se devuelve la carrera a tu saldo.'
              : '¿Seguro que quieres cancelar? Se devuelve la carrera a tu saldo.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    final provider = context.read<ConductorProvider>();
    setState(() => _trabajando = true);
    try {
      await provider.cancelar(_viaje.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Carrera cancelada. Tu saldo se mantiene.')),
      );
      widget.onCambio();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Widget _fila(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 16, color: AppColors.yellow),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
          ),
        ),
      ],
    );
  }
}
