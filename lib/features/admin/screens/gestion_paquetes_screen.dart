import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/conductor_provider.dart';

/// Gestion del catalogo de paquetes. La regla "magica" (2/5, 4/10, 8/20)
/// vive en el backend; aqui el admin los ve y, en produccion, los edita.
class GestionPaquetesScreen extends StatefulWidget {
  const GestionPaquetesScreen({super.key});

  @override
  State<GestionPaquetesScreen> createState() => _GestionPaquetesScreenState();
}

class _GestionPaquetesScreenState extends State<GestionPaquetesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConductorProvider>().cargarPaquetes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final paquetes = context.watch<ConductorProvider>().paquetes;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Paquetes de carreras',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        const SizedBox(height: 4),
        const Text(
          'Regla mágica: 10 carreras por 4 soles (0.40/carrera). Saldo por día, no acumulable.',
          style: TextStyle(fontSize: 12.5, color: AppColors.textDim, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...paquetes.map(
          (p) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(Icons.savings, color: AppColors.yellow),
              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('S/ ${p.monto}.00 → ${p.carreras} carreras'),
              trailing: const Icon(Icons.edit, color: AppColors.textDim),
            ),
          ),
        ),
        if (paquetes.isEmpty)
          const Text('Cargando paquetes...', style: TextStyle(color: AppColors.textDim)),
      ],
    );
  }
}
