import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/cliente_service.dart';

/// Home del cliente: pide un viaje. Tarifa minima 3 soles, pago directo
/// al conductor (Yape o efectivo).
class ClienteHomeScreen extends StatefulWidget {
  const ClienteHomeScreen({super.key});

  @override
  State<ClienteHomeScreen> createState() => _ClienteHomeScreenState();
}

class _ClienteHomeScreenState extends State<ClienteHomeScreen> {
  final _origen = TextEditingController();
  final _destino = TextEditingController();
  final _tarifa = TextEditingController(text: '3.0');
  String _metodo = 'yape';
  bool _cargando = false;
  String? _mensaje;

  @override
  void dispose() {
    _origen.dispose();
    _destino.dispose();
    _tarifa.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    final tarifa = double.tryParse(_tarifa.text.trim());
    if (tarifa == null || tarifa < 3.0) {
      setState(() => _mensaje = 'La tarifa mínima es de 3 soles');
      return;
    }
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await ClienteService.solicitarViaje(
        origenLat: 0, origenLng: 0, destinoLat: 0, destinoLng: 0,
        origenDireccion: _origen.text.trim(),
        destinoDireccion: _destino.text.trim(),
        tarifa: tarifa,
        metodoPago: _metodo,
      );
      setState(() => _mensaje = 'Viaje solicitado. Un conductor pronto lo tomará.');
    } catch (e) {
      setState(() => _mensaje = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Pedir un viaje', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.black)),
          const SizedBox(height: 16),
          TextField(
            controller: _origen,
            decoration: const InputDecoration(labelText: 'Origen', prefixIcon: Icon(Icons.place, color: AppColors.green)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _destino,
            decoration: const InputDecoration(labelText: 'Destino', prefixIcon: Icon(Icons.sports_motorsports, color: AppColors.blue)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tarifa,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Tarifa (mínimo S/ 3.00)', prefixText: 'S/ '),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Pago: ', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Yape'),
                selected: _metodo == 'yape',
                selectedColor: AppColors.yellow,
                onSelected: (_) => setState(() => _metodo = 'yape'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Efectivo'),
                selected: _metodo == 'efectivo',
                selectedColor: AppColors.yellow,
                onSelected: (_) => setState(() => _metodo = 'efectivo'),
              ),
            ],
          ),
          if (_mensaje != null) ...[
            const SizedBox(height: 12),
            Text(_mensaje!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _cargando ? null : _solicitar,
            child: Text(_cargando ? 'Solicitando...' : 'Solicitar viaje'),
          ),
        ],
      ),
    );
  }
}
