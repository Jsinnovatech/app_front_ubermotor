import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Dashboard del admin: metricas del negocio. Las reglas del saldo
/// (recargas del dia, viajes por estado) se ven aqui en produccion.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Resumen del día',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _Metrica(titulo: 'Conductores activos', valor: '0', color: AppColors.green)),
            SizedBox(width: 12),
            Expanded(child: _Metrica(titulo: 'Viajes completados', valor: '0', color: AppColors.blue)),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _Metrica(titulo: 'Recaudación recargas (S/)', valor: '0.00', color: AppColors.yellow)),
            SizedBox(width: 12),
            Expanded(child: _Metrica(titulo: 'Carreras vendidas', valor: '0', color: AppColors.black)),
          ],
        ),
        SizedBox(height: 24),
        Text(
          'Aquí se integrará el reporte real del backend (admin/). El negocio se sostiene con el prepago del saldo: cada conductor recarga cada día para operar.',
          style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textDim, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  final String titulo;
  final String valor;
  final Color color;

  const _Metrica({required this.titulo, required this.valor, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(valor, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: color)),
          const SizedBox(height: 4),
          Text(titulo, style: const TextStyle(fontSize: 11.5, color: AppColors.textDim, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
