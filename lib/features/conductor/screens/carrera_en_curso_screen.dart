import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';
import '../../../providers/conductor_provider.dart';
import 'calificar_screen.dart';

/// Pantalla de la carrera en curso del conductor. Muestra los 3 momentos:
/// - asignado: "En camino al cliente" + boton LLEGUE
/// - llegado:  "Esperando que el cliente suba" + boton INICIAR VIAJE
/// - en_curso: "En viaje al destino" + boton COMPLETAR
/// Al completar navega a la calificacion del rider.
class CarreraEnCursoScreen extends StatefulWidget {
  final Viaje viaje;
  const CarreraEnCursoScreen({super.key, required this.viaje});

  @override
  State<CarreraEnCursoScreen> createState() => _CarreraEnCursoScreenState();
}

class _CarreraEnCursoScreenState extends State<CarreraEnCursoScreen> {
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

    final (titulo, subtitulo, icono) = switch (estado) {
      'asignado' => ('En camino al cliente', 'Dirigete al punto de recogida', Icons.two_wheeler),
      'llegado' => ('Esperando al cliente', 'Tu conductor ya llego, el cliente esta por subir', Icons.hourglass_top),
      'en_curso' => ('En viaje al destino', 'Lleva a tu rider a su destino', Icons.navigation),
      _ => ('Carrera activa', '', Icons.two_wheeler),
    };

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        title: const Text(
          'Carrera en curso',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: AppColors.yellow),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.black,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              child: Column(
                children: [
                  Icon(icono, color: AppColors.yellow, size: 44),
                  const SizedBox(height: 12),
                  Text(
                    titulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitulo,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xB3FFFFFF)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _fila(Icons.person, 'Rider: ${v.riderNombre ?? 'Cliente'} · ⭐ ${v.riderRating?.toStringAsFixed(1) ?? '—'}'),
                  const Divider(height: 16),
                  _fila(Icons.place, v.origenDireccion ?? 'Origen'),
                  const SizedBox(height: 6),
                  _fila(Icons.sports_motorsports, v.destinoDireccion ?? 'Destino'),
                  const Divider(height: 16),
                  _fila(Icons.attach_money, 'S/ ${v.tarifa.toStringAsFixed(2)} · ${v.metodoPagoCliente}'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _botonSegunEstado(),
          ],
        ),
      ),
    );
  }

  Widget _botonSegunEstado() {
    final estado = _viaje.estado;
    if (_trabajando) {
      return const Center(child: CircularProgressIndicator(color: AppColors.yellow));
    }
    switch (estado) {
      case 'asignado':
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.blue,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _marcarLlegada,
          icon: const Icon(Icons.location_on, size: 22),
          label: const Text('LLEGUÉ AL PUNTO', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        );
      case 'llegado':
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _iniciarViaje,
          icon: const Icon(Icons.play_arrow, size: 26),
          label: const Text('INICIAR VIAJE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        );
      case 'en_curso':
        return ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: AppColors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _completarViaje,
          icon: const Icon(Icons.flag, size: 22),
          label: const Text('COMPLETAR VIAJE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Future<void> _marcarLlegada() async {
    setState(() => _trabajando = true);
    try {
      final viaje = await context.read<ConductorProvider>().llegar(_viaje.id);
      if (!mounted) return;
      setState(() => _viaje = viaje);
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _iniciarViaje() async {
    setState(() => _trabajando = true);
    try {
      final viaje = await context.read<ConductorProvider>().iniciar(_viaje.id);
      if (!mounted) return;
      setState(() => _viaje = viaje);
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Future<void> _completarViaje() async {
    setState(() => _trabajando = true);
    try {
      await context.read<ConductorProvider>().completar(_viaje.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => CalificarScreen(viaje: _viaje)),
      );
    } catch (e) {
      if (!mounted) return;
      _mostrarError(e);
    } finally {
      if (mounted) setState(() => _trabajando = false);
    }
  }

  Widget _fila(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, size: 18, color: AppColors.yellow),
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

  void _mostrarError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
    );
  }
}
