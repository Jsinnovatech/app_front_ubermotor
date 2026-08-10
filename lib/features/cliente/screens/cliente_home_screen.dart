import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/cliente_service.dart';

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

  @override
  void dispose() {
    _origen.dispose();
    _destino.dispose();
    super.dispose();
  }

  Future<void> _solicitar() async {
    if (_destino.text.trim().isEmpty) {
      setState(() => _mensaje = 'Indica el destino');
      return;
    }
    setState(() {
      _cargando = true;
      _mensaje = null;
    });
    try {
      await ClienteService.solicitarViaje(
        origenLat: 0,
        origenLng: 0,
        destinoLat: 0,
        destinoLng: 0,
        origenDireccion: _origen.text.trim(),
        destinoDireccion: _destino.text.trim(),
        tarifa: 3.0,
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
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.gray,
        elevation: 0,
        title: Text(
          'Hola, ${auth.sesion?.nombre ?? ''}',
          style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.black),
        ),
        actions: [
          IconButton(
            tooltip: 'Salir',
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
            icon: const Icon(Icons.logout, color: AppColors.yellow),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // "Mapa" placeholder
            Expanded(
              child: Container(
                color: const Color(0xFFE2E3E0),
                alignment: Alignment.center,
                child: const Icon(Icons.location_on, size: 40, color: AppColors.black),
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
                                decoration: const InputDecoration(
                                  hintText: 'Punto de partida',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
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
          ],
        ),
      ),
    );
  }

  Widget _botonStepper(IconData icono, {required VoidCallback onTap}) {
    return Container(
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
