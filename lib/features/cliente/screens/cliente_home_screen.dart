import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/boton_sos.dart';
import '../../../models/conductor_disponible_model.dart';
import '../../../models/viaje_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cliente_provider.dart';
import '../../../providers/modo_app_provider.dart';
import '../../../services/cliente_service.dart';
import '../../../services/geocoding_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/sos_service.dart';
import '../../../services/ubicacion_service.dart';
import '../widgets/detalle_conductor_sheet.dart';
import 'historial_cliente_screen.dart';
import '../../ranking/screens/ranking_screen.dart';

/// Home del cliente replicado del diseno de Stitch (MotoRide):
/// panel "¿A donde vamos?" con linea conectora origen/destino,
/// stepper de tarifa (minimo S/ 3.00), toggle Efectivo/Yape,
/// y boton "Pedir viaje".
class ClienteHomeScreen extends StatefulWidget {
  /// true cuando es un CONDUCTOR viendo la app en "modo pasajero" (como
  /// InDrive): muestra el boton para volver al modo conductor.
  final bool desdeConductor;
  const ClienteHomeScreen({super.key, this.desdeConductor = false});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  final _origen = TextEditingController(text: 'Mi ubicación actual');
  final _destino = TextEditingController();
  final _tarifa = TextEditingController(text: '3.00');
  double _tarifaValor = 3.0;
  String _metodo = 'efectivo';
  bool _cargando = false;
  String? _mensaje;
  double _miLat = -12.0464;
  double _miLng = -77.0428;
  bool _ubicacionCargada = false;
  List<SugerenciaLugar> _sugerencias = [];
  bool _buscandoDestino = false;
  String? _destinoSeleccionado;
  double? _destinoLat;
  double? _destinoLng;
  // Tracking en vivo: posicion del conductor de mi viaje activo.
  double? _conductorLat;
  double? _conductorLng;
  String? _estadoViaje;
  RealtimeService? _realtime;
  // Perfil del cliente (para la foto y metricas).
  int _viajesRealizados = 0;
  double _rating = 5.0;
  String? _fotoUrl;
  int _centrarKey = 0;
  final _sheetController = DraggableScrollableController();
  // Viaje activo: cuando un conductor acepta, aparece la tarjeta del conductor
  // en la parte de abajo (además del push).
  Viaje? _viajeActivo;
  Timer? _viajeTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Ubicacion real del cliente para el mapa y las motos mas cercanas.
      final posicion = await UbicacionService.obtenerPosicionActual();
      final lat = posicion?.latitude ?? -12.0464;
      final lng = posicion?.longitude ?? -77.0428;
      if (mounted) {
        setState(() {
          _miLat = lat;
          _miLng = lng;
          _ubicacionCargada = true;
        });
        // Reverse geocoding: convierte las coords en la direccion del origen.
        final direccion = await GeocodingService.reverse(lat, lng);
        if (mounted && direccion != null) {
          _origen.text = direccion;
        }
        context.read<ClienteProvider>().cargarConductores(lat: lat, lng: lng);
      }
      _conectarTracking();
      _cargarPerfil();
      _revisarViajeActivo();
      _iniciarMonitoreoViaje();
    });
    _destino.addListener(_onDestinoCambio);
    _tarifa.addListener(_onTarifaManual);
  }

  /// Consulta cada 5s el viaje activo del cliente: cuando un conductor
  /// acepta, actualiza [_viajeActivo] y aparece la tarjeta del conductor.
  void _iniciarMonitoreoViaje() {
    _viajeTimer?.cancel();
    _viajeTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        final viaje = await ClienteService.viajeActivo();
        if (!mounted) return;
        setState(() => _viajeActivo = viaje);
      } catch (_) {}
    });
  }

  /// Cuando el usuario escribe el monto a mano, actualiza _tarifaValor.
  void _onTarifaManual() {
    final texto = _tarifa.text.replaceAll(',', '.').trim();
    final valor = double.tryParse(texto);
    if (valor != null && valor >= 3.0) {
      _tarifaValor = (valor * 100).round() / 100;
    }
  }

  /// Carga el perfil del cliente (nombre, foto, viajes, rating).
  Future<void> _cargarPerfil() async {
    try {
      final perfil = await ClienteService.perfil();
      if (!mounted) return;
      setState(() {
        _viajesRealizados = perfil.viajesRealizados;
        _rating = perfil.ratingPromedio;
        _fotoUrl = perfil.fotoUrl;
      });
    } catch (_) {}
  }

  /// Si el cliente tiene un viaje en curso al entrar (cerro la pantalla o
  /// recargo), redirige a la pantalla de seguimiento para que vea el aviso.
  Future<void> _revisarViajeActivo() async {
    try {
      final viaje = await ClienteService.viajeActivo();
      if (viaje != null && mounted) {
        // Aviso compacto, no una pantalla completa: el cliente sigue en el
        // Home y ve la confirmacion de que su viaje sigue en curso.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.black,
            behavior: SnackBarBehavior.floating,
            content: Text(
              '🛺 Tienes un viaje en curso',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow),
            ),
          ),
        );
      }
    } catch (_) {}
  }

  /// Abre el selector de imagen y sube la foto de perfil del cliente.
  Future<void> _subirFotoPerfil() async {
    if (!mounted) return;
    try {
      final picker = ImagePicker();
      final imagen = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
      if (imagen == null || !mounted) return;

      final bytes = await imagen.readAsBytes();
      final nombre = imagen.name.split('/').last;

      await ClienteService.subirFoto(bytes: bytes, nombreArchivo: nombre);
      if (!mounted) return;
      await _cargarPerfil(); // refresca la foto en el AppBar
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil actualizada')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la foto: $e')),
      );
    }
  }

  @override
  void dispose() {
    _viajeTimer?.cancel();
    _origen.dispose();
    _destino.dispose();
    _tarifa.dispose();
    _realtime?.desconectar();
    super.dispose();
  }

  /// Conexion WebSocket del cliente: recibe la ubicacion del conductor en vivo
  /// mientras dure el viaje (el pin se mueve en el mapa, patron InDrive).
  Future<void> _conectarTracking() async {
    final realtime = RealtimeService();
    _realtime = realtime;
    realtime.onUbicacionConductor = (viajeId, lat, lng) {
      if (!mounted) return;
      setState(() {
        _conductorLat = lat;
        _conductorLng = lng;
      });
    };
    await realtime.conectarCliente();
  }

  /// Menu hamburguesa del cliente: foto, nombre, opciones y, si viene de un
  /// conductor en modo pasajero, el switch para volver al modo conductor.
  void _abrirMenuCliente() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sesion = context.read<AuthProvider>().sesion;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 42,
                        backgroundColor: AppColors.yellow,
                        backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                        child: _fotoUrl == null
                            ? const Icon(Icons.person, size: 44, color: AppColors.black)
                            : null,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        sesion?.nombre ?? 'Pasajero',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Pasajero',
                        style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.line),
                ListTile(
                  leading: const Icon(Icons.history, color: AppColors.black),
                  title: const Text('Mis viajes', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistorialClienteScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events, color: AppColors.black),
                  title: const Text('Ranking', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RankingScreen()));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.black),
                  title: const Text('Cerrar sesión', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.black)),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.textDim),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    context.read<AuthProvider>().cerrarSesion();
                  },
                ),
                if (widget.desdeConductor) ...[
                  const Divider(color: AppColors.line),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.two_wheeler, color: AppColors.yellow, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Modo conductor',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.black)),
                              Text('Vuelve a aceptar carreras con la misma cuenta',
                                  style: TextStyle(fontSize: 11, color: AppColors.textDim)),
                            ],
                          ),
                        ),
                        Switch(
                          value: !context.watch<ModoAppProvider>().esPasajero,
                          activeTrackColor: AppColors.yellow,
                          onChanged: (_) {
                            Navigator.of(ctx).pop();
                            context.read<ModoAppProvider>().cambiarModo(false);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Autocompletado del destino mientras se escribe (debounce simple).
  Future<void> _onDestinoCambio() async {
    final texto = _destino.text.trim();
    if (texto.isEmpty || _destinoSeleccionado == texto) {
      if (texto.isEmpty) {
        if (mounted && _sugerencias.isNotEmpty) setState(() => _sugerencias = []);
      }
      return;
    }
    setState(() => _buscandoDestino = true);
    final resultado = await GeocodingService.autocompletar(texto, lat: _miLat, lng: _miLng);
    if (mounted) setState(() {
      _sugerencias = resultado;
      _buscandoDestino = false;
    });
  }

  void _usarUbicacionActual() async {
    final posicion = await UbicacionService.obtenerPosicionActual();
    if (posicion == null || !mounted) {
      if (mounted) setState(() => _mensaje = 'No se pudo obtener tu ubicación. Revisa los permisos.');
      return;
    }
    setState(() {
      _miLat = posicion.latitude;
      _miLng = posicion.longitude;
      _ubicacionCargada = true;
      _sugerencias = [];
    });
    final direccion = await GeocodingService.reverse(posicion.latitude, posicion.longitude);
    if (mounted && direccion != null) _origen.text = direccion;
    context.read<ClienteProvider>().cargarConductores(lat: posicion.latitude, lng: posicion.longitude);
  }

  Future<void> _solicitar() async {
    if (_destino.text.trim().isEmpty) {
      setState(() => _mensaje = 'Indica el destino');
      return;
    }
    if (_destinoLat == null) {
      setState(() => _mensaje = 'Selecciona el destino del autocompletado');
      return;
    }
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await ClienteService.solicitarViaje(
        origenLat: _miLat,
        origenLng: _miLng,
        destinoLat: _destinoLat!,
        destinoLng: _destinoLng!,
        origenDireccion: _origen.text.trim(),
        destinoDireccion: _destino.text.trim(),
        tarifa: _tarifaValor,
        metodoPago: _metodo,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.black,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '🛺 Viaje solicitado. Buscando un conductor...',
            style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _mensaje = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
                onPressed: _abrirMenuCliente,
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
          // Foto de perfil del cliente a la altura del AppBar
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: _subirFotoPerfil,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.yellow,
                backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                child: _fotoUrl == null
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
            child: _MapaUbicacion(
              lat: _miLat,
              lng: _miLng,
              ubicacionCargada: _ubicacionCargada,
              conductorLat: _conductorLat,
              conductorLng: _conductorLng,
              centrarKey: _centrarKey,
            ),
          ),
          // Boton flotante "Mi ubicacion": centra la camara en el GPS
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'btn_ubicacion',
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.blue,
              onPressed: _centrarEnMiUbicacion,
              child: const Icon(Icons.my_location),
            ),
          ),
          // Tarjeta del conductor cuando acepto la carrera (parte de abajo)
          if (_viajeActivo != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: _TarjetaConductorActivo(
                viaje: _viajeActivo!,
                onVerRuta: () => _centrarEnMiUbicacion(),
              ),
            ),
          // Panel deslizante: tarjeta 35% <-> pantalla completa 85% (snap)
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.42,
            minChildSize: 0.25,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.42, 0.9],
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
                    const SizedBox(height: 10),
                    // Fila de metricas: viajes | rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _metrica(
                          label: 'Tus viajes',
                          valor: '${_viajesRealizados}',
                          icono: Icons.route,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HistorialClienteScreen()),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _metrica(
                          label: 'Tu rating',
                          valor: '⭐ ${_rating.toStringAsFixed(1)}',
                          icono: Icons.star,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RankingScreen()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      '¿A dónde vamos?',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black),
                    ),
                    const SizedBox(height: 10),
                  // Linea conectora origen/destino
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              const Icon(Icons.circle, size: 12, color: AppColors.yellow),
                              Expanded(
                                child: Container(
                                  width: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  color: AppColors.line,
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.black, width: 2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              TextField(
                                controller: _origen,
                                style: const TextStyle(fontSize: 16, color: AppColors.black),
                                decoration: InputDecoration(
                                  hintText: 'Punto de partida',
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                                  suffixIcon: IconButton(
                                    tooltip: 'Usar mi ubicación actual',
                                    icon: const Icon(Icons.my_location, color: AppColors.blue, size: 20),
                                    onPressed: _usarUbicacionActual,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _destino,
                                style: const TextStyle(fontSize: 16, color: AppColors.black),
                                onTap: _expandirSheet,
                                decoration: const InputDecoration(
                                  hintText: 'Buscar destino',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                                ),
                              ),
                              // Sugerencias de autocompletado del destino
                              if (_sugerencias.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.line),
                                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                  ),
                                  child: Column(
                                    children: _sugerencias.map((s) {
                                      return InkWell(
                                        onTap: () {
                                          setState(() {
                                            _destino.text = s.nombre;
                                            _destinoSeleccionado = s.nombre;
                                            _destinoLat = s.lat;
                                            _destinoLng = s.lng;
                                            _sugerencias = [];
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.place, size: 16, color: AppColors.yellow),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  s.nombre,
                                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.black),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                )
                              else if (_buscandoDestino)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
                                      SizedBox(width: 8),
                                      Text('Buscando...', style: TextStyle(fontSize: 12, color: AppColors.textDim)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Dos columnas: precio (con stepper) | metodo de pago apilado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Columna 1: input del precio con botones - y +
                      Expanded(
                        child: Row(
                          children: [
                            _botonStepper(Icons.remove, onTap: _disminuirTarifa),
                            Expanded(
                              child: TextField(
                                controller: _tarifa,
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.black),
                                decoration: const InputDecoration(
                                  prefixText: 'S/ ',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                                ),
                              ),
                            ),
                            _botonStepper(Icons.add, onTap: _aumentarTarifa),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Columna 2: Efectivo y Yape apilados en dos filas
                      Expanded(
                        child: Column(
                          children: [
                            _chipPagoFila('Efectivo', Icons.payments),
                            const SizedBox(height: 6),
                            _chipPagoFila('Yape', Icons.qr_code_scanner),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tarifa mínima S/ 3.00 · pago directo al conductor',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  if (_mensaje != null) ...[
                    Text(_mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                  ],
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _solicitar,
                      child: Text(_cargando ? 'Solicitando...' : 'Pedir viaje'),
                    ),
                  ),
                    const SizedBox(height: 18),
                    // Motos disponibles cerca (dentro del sheet deslizante)
                    _MotosCerca(
                      conductores: context.watch<ClienteProvider>().conductores,
                      onConductorTap: (c) => showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: AppColors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (_) => DetalleConductorSheet(conductor: c),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: BotonSos(onDisparar: _dispararSos),
      bottomNavigationBar: _BottomNavCliente(
        onViajes: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const HistorialClienteScreen()),
        ),
        onRanking: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RankingScreen()),
        ),
        onSalir: () => context.read<AuthProvider>().cerrarSesion(),
      ),
    );
  }

  /// Tarjeta de metrica del Home del cliente.
  Widget _metrica({
    required String label,
    required String valor,
    required IconData icono,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.line, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icono, size: 15, color: AppColors.yellow),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    valor,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: AppColors.textDim, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }

  /// Expande el panel deslizante al tocar el campo de destino (estilo InDrive).
  void _expandirSheet() {
    _sheetController.animateTo(
      0.9,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// Centra la camara del mapa en la ubicacion actual del cliente.
  Future<void> _centrarEnMiUbicacion() async {
    final posicion = await UbicacionService.obtenerPosicionActual();
    if (posicion == null || !mounted) return;
    setState(() {
      _miLat = posicion.latitude;
      _miLng = posicion.longitude;
      _ubicacionCargada = true;
      _centrarKey++;
    });
    context.read<ClienteProvider>().cargarConductores(lat: posicion.latitude, lng: posicion.longitude);
  }

  Future<void> _dispararSos() async {
    if (!mounted) return;
    try {
      await SosService.activar(lat: -12.0464, lng: -77.0428);      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.red,
          content: Text('Alerta SOS enviada a Serenazgo/Policía', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
        );
      }
    }
  }

  Widget _botonStepper(IconData icono, {required VoidCallback onTap}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icono, color: AppColors.black),
        onPressed: onTap,
      ),
    );
  }

  Widget _chipPagoFila(String label, IconData icono) {
    final seleccionado = _metodo == label.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _metodo = label.toLowerCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.black),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 16, color: seleccionado ? AppColors.white : AppColors.black),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: seleccionado ? AppColors.white : AppColors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Sube la tarifa de a 0.50 (minimo 3.00).
  void _aumentarTarifa() {
    _cambiarTarifa(_tarifaValor + 0.50);
  }

  /// Baja la tarifa de a 0.50 (minimo 3.00).
  void _disminuirTarifa() {
    _cambiarTarifa(_tarifaValor - 0.50);
  }

  void _cambiarTarifa(double valor) {
    final nuevo = (valor * 100).round() / 100;
    final minimo = 3.0;
    final final_ = nuevo < minimo ? minimo : nuevo;
    setState(() {
      _tarifaValor = final_;
      _tarifa.text = final_.toStringAsFixed(2);
    });
  }
}

/// Lista de motos disponibles cerca del cliente, con reputacion.
class _MotosCerca extends StatelessWidget {
  final List<ConductorDisponible> conductores;
  final void Function(ConductorDisponible c) onConductorTap;

  const _MotosCerca({required this.conductores, required this.onConductorTap});

  @override
  Widget build(BuildContext context) {
    if (conductores.isEmpty) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        color: AppColors.white,
        child: const Text(
          'Buscando motos cerca...',
          style: TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
        ),
      );
    }
    return Container(
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              'Motos disponibles cerca (${conductores.length})',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.black),
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: conductores.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _TarjetaMoto(
                conductor: conductores[i],
                onTap: () => onConductorTap(conductores[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaMoto extends StatelessWidget {
  final ConductorDisponible conductor;
  final VoidCallback onTap;

  const _TarjetaMoto({required this.conductor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: AppColors.yellow, size: 14),
                const SizedBox(width: 4),
                Text(
                  conductor.ratingPromedio.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.black),
                ),
                const Spacer(),
                Text(
                  '${conductor.distanciaKm.toStringAsFixed(1)}km',
                  style: const TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (conductor.moto.fotoUrl != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(conductor.moto.fotoUrl!, width: 34, height: 34, fit: BoxFit.cover),
                  )
                else
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.two_wheeler, size: 18, color: AppColors.black),
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        conductor.nombre,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.black),
                      ),
                      Text(
                        '${conductor.moto.marca ?? ''} ${conductor.moto.modelo ?? ''}'.trim(),
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Mapa de la ubicacion actual del cliente para reconfirmarla antes de pedir
/// el viaje (OpenStreetMap, sin API key). Pin azul en la posicion actual.
/// Si hay un conductor asignado, se muestra su pin (moto) moviendose en vivo.
class _MapaUbicacion extends StatefulWidget {
  final double lat;
  final double lng;
  final bool ubicacionCargada;
  final double? conductorLat;
  final double? conductorLng;
  final int centrarKey;

  const _MapaUbicacion({
    required this.lat,
    required this.lng,
    required this.ubicacionCargada,
    this.conductorLat,
    this.conductorLng,
    this.centrarKey = 0,
  });

  @override
  State<_MapaUbicacion> createState() => _MapaUbicacionState();
}

class _MapaUbicacionState extends State<_MapaUbicacion> {
  final MapController _mapController = MapController();

  @override
  void didUpdateWidget(covariant _MapaUbicacion oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Al pulsar "Mi ubicacion" (cambia centrarKey) recentra la camara.
    if (oldWidget.centrarKey != widget.centrarKey &&
        _mapController.camera != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(widget.lat, widget.lng), 16);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.ubicacionCargada) {
      return Container(
        color: const Color(0xFFE2E3E0),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.yellow),
      );
    }

    final marcadores = <Marker>[
      Marker(
        point: LatLng(widget.lat, widget.lng),
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: AppColors.blue, size: 40),
      ),
    ];
    // Pin del conductor en vivo (tracking del viaje)
    if (widget.conductorLat != null && widget.conductorLng != null) {
      marcadores.add(
        Marker(
          point: LatLng(widget.conductorLat!, widget.conductorLng!),
          width: 44,
          height: 44,
          child: const Icon(Icons.sports_motorsports, color: AppColors.green, size: 44),
        ),
      );
    }

    final hayConductor = widget.conductorLat != null && widget.conductorLng != null;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(widget.lat, widget.lng),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.jsinnovatech.hablavas',
              ),
              // Radio de ubicacion: circulo de 1km alrededor de donde esta el
              // cliente, para que entienda el area donde buscan motos.
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: LatLng(widget.lat, widget.lng),
                    radius: 1000, // 1km en metros
                    useRadiusInMeter: true,
                    color: AppColors.yellow.withOpacity(0.10),
                    borderColor: AppColors.yellow,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(markers: marcadores),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 10,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: hayConductor ? AppColors.green : AppColors.line),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hayConductor ? Icons.sports_motorsports : Icons.my_location,
                    size: 14,
                    color: hayConductor ? AppColors.green : AppColors.blue,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    hayConductor ? 'Tu conductor en camino' : 'Tu ubicación actual',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bottom nav del cliente: Home | Mis viajes | Mi cuenta (foto/salir).
class _BottomNavCliente extends StatelessWidget {
  final VoidCallback onViajes;
  final VoidCallback onRanking;
  final VoidCallback onSalir;

  const _BottomNavCliente({
    required this.onViajes,
    required this.onRanking,
    required this.onSalir,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home, 'Home', () {}),
      (Icons.history, 'Viajes', onViajes),
      (Icons.leaderboard, 'Ranking', onRanking),
      (Icons.logout, 'Salir', onSalir),
    ];
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: items.map((item) {
          final (icono, label, onTap) = item;
          return Expanded(
            child: InkWell(
              onTap: onTap,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icono, size: 24, color: AppColors.yellow, fill: label == 'Home' ? 1 : 0),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tarjeta del conductor en la parte de abajo del Home del cliente cuando
/// aceptó su carrera: foto, nombre, rating, moto y placa + estado del viaje.
class _TarjetaConductorActivo extends StatelessWidget {
  final Viaje viaje;
  final VoidCallback onVerRuta;

  const _TarjetaConductorActivo({required this.viaje, required this.onVerRuta});

  @override
  Widget build(BuildContext context) {
    final estado = viaje.estado;
    final (titulo, color, icono) = switch (estado) {
      'asignado' => ('Conductor en camino', AppColors.blue, Icons.near_me),
      'llegado' => ('Tu conductor llegó', AppColors.yellow, Icons.place),
      'en_curso' => ('En viaje al destino', AppColors.green, Icons.two_wheeler),
      _ => ('Carrera en curso', AppColors.black, Icons.two_wheeler),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 2),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.yellow,
            backgroundImage: viaje.conductorFotoUrl != null
                ? NetworkImage(viaje.conductorFotoUrl!)
                : null,
            child: viaje.conductorFotoUrl == null
                ? const Icon(Icons.person, size: 28, color: AppColors.black)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        viaje.conductorNombre ?? 'Tu conductor',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppColors.black),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '⭐ ${viaje.conductorRating?.toStringAsFixed(1) ?? '—'}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (viaje.motoDescripcion != null) viaje.motoDescripcion!,
                    if (viaje.motoPlaca != null) viaje.motoPlaca!,
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textDim, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(icono, size: 16, color: color),
                    const SizedBox(width: 4),
                    Text(
                      titulo,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
