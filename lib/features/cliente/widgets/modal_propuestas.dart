import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/viaje_model.dart';
import '../../../services/realtime_service.dart';
import '../../../services/viaje_service.dart';

/// Modal de propuestas (patron InDrive): el cliente ve las ofertas de los
/// conductores de a 3, puede pedir "Ver mas ofertas" o cancelar el viaje.
/// Devuelve el Viaje asignado (o null si cierra/cancela).
Future<Viaje?> mostrarModalPropuestas(
  BuildContext context, {
  required int viajeId,
  RealtimeService? realtime,
}) {
  return showModalBottomSheet<Viaje>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => ModalPropuestas(viajeId: viajeId, realtime: realtime),
  );
}

class ModalPropuestas extends StatefulWidget {
  final int viajeId;
  final RealtimeService? realtime;

  const ModalPropuestas({super.key, required this.viajeId, this.realtime});

  @override
  State<ModalPropuestas> createState() => _ModalPropuestasState();
}

class _ModalPropuestasState extends State<ModalPropuestas> {
  List<ViajeOferta> _ofertas = [];
  bool _cargando = true;
  bool _cargandoMas = false;
  bool _tieneMas = false;
  bool _aceptando = false;
  String? _error;
  Timer? _timer;
  int _nuevaOfertaFlash = 0;

  int get _viajeId => widget.viajeId;

  @override
  void initState() {
    super.initState();
    final realtime = widget.realtime;
    if (realtime != null) {
      _callbackPrevio = realtime.onOfertaNueva;
      realtime.onOfertaNueva = (viajeId, ofertaId, precio) {
        if (viajeId != _viajeId) return;
        if (!mounted) return;
        setState(() => _nuevaOfertaFlash++);
        _refrescar();
      };
    }
    _refrescar();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _refrescar());
  }

  void Function(int, int, double)? _callbackPrevio;

  @override
  void dispose() {
    _timer?.cancel();
    final realtime = widget.realtime;
    if (realtime != null) realtime.onOfertaNueva = _callbackPrevio;
    super.dispose();
  }

  /// Recarga las paginas cargadas (offset 0, 3, 6...) para reflejar ofertas
  /// nuevas y descartar las vencidas (30s).
  Future<void> _refrescar() async {
    try {
      final lista = <ViajeOferta>[];
      var offset = 0;
      var hayMas = true;
      while (hayMas && lista.length <= _ofertas.length) {
        final pagina = await ViajeService.ofertas(_viajeId, offset: offset);
        lista.addAll(pagina);
        hayMas = pagina.length == 3;
        offset += 3;
      }
      if (!mounted) return;
      setState(() {
        _ofertas = lista;
        _tieneMas = hayMas;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', '');
      });
    }
  }

  Future<void> _verMas() async {
    if (_cargandoMas) return;
    setState(() => _cargandoMas = true);
    try {
      final pagina = await ViajeService.ofertas(_viajeId, offset: _ofertas.length);
      if (!mounted) return;
      setState(() {
        _ofertas = [..._ofertas, ...pagina];
        _tieneMas = pagina.length == 3;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    } finally {
      if (mounted) setState(() => _cargandoMas = false);
    }
  }

  Future<void> _aceptar(ViajeOferta oferta) async {
    if (_aceptando) return;
    setState(() => _aceptando = true);
    try {
      final viaje = await ViajeService.aceptarOferta(
        viajeId: _viajeId,
        ofertaId: oferta.id,
      );
      if (!mounted) return;
      Navigator.of(context).pop(viaje);
    } catch (e) {
      if (!mounted) return;
      setState(() => _aceptando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    }
  }

  Future<void> _cancelarViaje() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar viaje', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('¿Seguro que quieres cancelar la búsqueda? La carrera se devuelve a tu saldo.'),
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
    try {
      await ViajeService.cancelar(_viajeId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Propuestas de conductores',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              const SizedBox(height: 4),
              const Text(
                'Elige la que prefieras: el precio y el conductor son tuyos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              // Chip de aviso cuando llega una oferta nueva por WebSocket
              if (_nuevaOfertaFlash > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.yellowSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_active, size: 14, color: AppColors.black),
                      SizedBox(width: 6),
                      Text('¡Nueva propuesta!', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.black)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Expanded(
                child: _cargando
                    ? const Center(child: CircularProgressIndicator(color: AppColors.yellow))
                    : _cuerpo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    if (_error != null && _ofertas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Buscando conductores que oferten...',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black)),
            const SizedBox(height: 6),
            Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.textDim)),
          ],
        ),
      );
    }

    if (_ofertas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.yellow),
            SizedBox(height: 12),
            Text(
              'Buscando conductores que oferten...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.black),
            ),
            SizedBox(height: 4),
            Text(
              'Los conductores cercanos están ofreciendo su precio.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return ListView(
      children: [
        ..._ofertas.map((o) => _tarjeta(o)),
        const SizedBox(height: 8),
        if (_tieneMas)
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: _cargandoMas ? null : _verMas,
              icon: _cargandoMas
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh, size: 18),
              label: const Text('Ver más ofertas', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: AppColors.red),
              ),
            ),
            onPressed: _aceptando ? null : _cancelarViaje,
            child: const Text('Cancelar viaje', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    );
  }

  Widget _tarjeta(ViajeOferta o) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gray,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.yellow,
                backgroundImage: o.conductorFotoUrl != null ? NetworkImage(o.conductorFotoUrl!) : null,
                child: o.conductorFotoUrl == null
                    ? const Icon(Icons.person, size: 24, color: AppColors.black)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o.conductorNombre ?? 'Conductor',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.black),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (o.conductorRating != null) '⭐ ${o.conductorRating!.toStringAsFixed(1)}',
                        if (o.motoDescripcion != null) o.motoDescripcion!,
                        if (o.motoPlaca != null) o.motoPlaca!,
                      ].join(' · '),
                      style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'S/ ${o.precioOfertado.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.black),
              ),
              const Spacer(),
              if (o.distanciaKm != null) ...[
                const Icon(Icons.near_me, size: 14, color: AppColors.textDim),
                const SizedBox(width: 4),
                Text(
                  '${o.distanciaKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim),
                ),
              ],
              if (o.etaMinutos != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.schedule, size: 14, color: AppColors.textDim),
                const SizedBox(width: 4),
                Text(
                  '~${o.etaMinutos} min',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _aceptando ? null : () => _aceptar(o),
              child: Text(
                _aceptando ? 'Aceptando...' : 'Aceptar esta propuesta',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
