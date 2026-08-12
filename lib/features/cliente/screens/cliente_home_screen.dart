import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/boton_sos.dart';
import '../../../models/conductor_disponible_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/cliente_provider.dart';
import '../../../services/cliente_service.dart';
import '../../../services/geocoding_service.dart';
import '../../../services/realtime_service.dart';
import '../../../services/sos_service.dart';
import '../../../services/ubicacion_service.dart';
import '../widgets/detalle_conductor_sheet.dart';
import 'historial_cliente_screen.dart';
import 'seguimiento_viaje_screen.dart';
import '../../ranking/screens/ranking_screen.dart';

/// Home del cliente replicado del diseno de Stitch (MotoRide):
/// panel "¿A donde vamos?" con linea conectora origen/destino,
/// stepper de tarifa (minimo S/ 3.00), toggle Efectivo/Yape,
/// y boton "Pedir viaje".
class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  final _origen = TextEditingController(text: 'Mi ubicación actual');
  final _destino = TextEditingController();
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
    });
    _destino.addListener(_onDestinoCambio);
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
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => SeguimientoViajeScreen(viaje: viaje)),
        );
      }
    } catch (_) {}
  }

  /// Abre el selector de imagen para la foto de perfil del cliente.
  Future<void> _subirFotoPerfil() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('La foto de perfil se habilita desde la app móvil')),
    );
  }

  @override
  void dispose() {
    _origen.dispose();
    _destino.dispose();
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

  /// Autocompletado del destino mientras se escribe (debounce simple).
  Future<void> _onDestinoCambio() async {
    final texto = _destino.text.trim();
    if (texto.length < 3 || _destinoSeleccionado == texto) {
      if (texto.length < 3) {
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
      final viaje = await ClienteService.solicitarViaje(
        origenLat: _miLat,
        origenLng: _miLng,
        destinoLat: _destinoLat!,
        destinoLng: _destinoLng!,
        origenDireccion: _origen.text.trim(),
        destinoDireccion: _destino.text.trim(),
        tarifa: 3.0,
        metodoPago: _metodo,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => SeguimientoViajeScreen(viaje: viaje)),
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
        title: const Text(
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
        actions: [
          IconButton(
            tooltip: 'Mis viajes',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const HistorialClienteScreen()),
            ),
            icon: const Icon(Icons.history, color: AppColors.black),
          ),
          IconButton(
            tooltip: 'Salir',
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
            icon: const Icon(Icons.logout, color: AppColors.black),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Fila de metricas: viajes realizados | rating
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                children: [
                  Expanded(
                    child: _metrica(
                      label: 'Tus viajes',
                      valor: '${_viajesRealizados}',
                      icono: Icons.route,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HistorialClienteScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _metrica(
                      label: 'Tu rating',
                      valor: '⭐ ${_rating.toStringAsFixed(1)}',
                      icono: Icons.star,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RankingScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _subirFotoPerfil,
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
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.yellowSoft,
                              backgroundImage: _fotoUrl != null ? NetworkImage(_fotoUrl!) : null,
                              child: _fotoUrl == null
                                  ? const Icon(Icons.add_a_photo, size: 18, color: AppColors.black)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Mi foto',
                              style: TextStyle(fontSize: 11, color: AppColors.textDim, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Mapa con la ubicacion actual del cliente (para reconfirmar)
            Expanded(
              flex: 3,
              child: _MapaUbicacion(
                lat: _miLat,
                lng: _miLng,
                ubicacionCargada: _ubicacionCargada,
                conductorLat: _conductorLat,
                conductorLng: _conductorLng,
              ),
            ),
            // Panel de solicitud
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿A dónde vamos?',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.black),
                  ),
                  const SizedBox(height: 16),
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
                  const SizedBox(height: 16),
                  const Text(
                    'Ofrece tu tarifa',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _botonStepper(Icons.remove, onTap: () {}),
                      const Expanded(
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.black),
                          decoration: InputDecoration(
                            prefixText: 'S/ ',
                            hintText: '3.00',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
                          ),
                        ),
                      ),
                      _botonStepper(Icons.add, onTap: () {}),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tarifa mínima S/ 3.00',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _chipPago('Efectivo', Icons.payments)),
                      const SizedBox(width: 12),
                      Expanded(child: _chipPago('Yape', Icons.qr_code_scanner)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_mensaje != null) ...[
                    Text(_mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _cargando ? null : _solicitar,
                      child: Text(_cargando ? 'Solicitando...' : 'Pedir viaje'),
                    ),
                  ),
                ],
              ),
            ),
            // Motos disponibles cerca
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
    );
  }

  Future<void> _dispararSos() async {
    if (!mounted) return;
    try {
      await SosService.activar(lat: -12.0464, lng: -77.0428);
      if (!mounted) return;
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

  Widget _botonStepper(IconData icono, {required VoidCallback onTap}) {    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: IconButton(
        icon: Icon(icono, color: AppColors.black),
        onPressed: onTap,
      ),
    );
  }

  Widget _chipPago(String label, IconData icono) {
    final seleccionado = _metodo == label.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => _metodo = label.toLowerCase()),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: seleccionado ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.black),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icono, size: 18, color: seleccionado ? AppColors.white : AppColors.black),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: seleccionado ? AppColors.white : AppColors.black),
            ),
          ],
        ),
      ),
    );
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
class _MapaUbicacion extends StatelessWidget {
  final double lat;
  final double lng;
  final bool ubicacionCargada;
  final double? conductorLat;
  final double? conductorLng;

  const _MapaUbicacion({
    required this.lat,
    required this.lng,
    required this.ubicacionCargada,
    this.conductorLat,
    this.conductorLng,
  });

  @override
  Widget build(BuildContext context) {
    if (!ubicacionCargada) {
      return Container(
        color: const Color(0xFFE2E3E0),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(color: AppColors.yellow),
      );
    }

    final marcadores = <Marker>[
      Marker(
        point: LatLng(lat, lng),
        width: 40,
        height: 40,
        child: const Icon(Icons.my_location, color: AppColors.blue, size: 40),
      ),
    ];
    // Pin del conductor en vivo (tracking del viaje)
    if (conductorLat != null && conductorLng != null) {
      marcadores.add(
        Marker(
          point: LatLng(conductorLat!, conductorLng!),
          width: 44,
          height: 44,
          child: const Icon(Icons.sports_motorsports, color: AppColors.green, size: 44),
        ),
      );
    }

    final hayConductor = conductorLat != null && conductorLng != null;

    return Stack(
      children: [
        Positioned.fill(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(lat, lng),
              initialZoom: 15,
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
