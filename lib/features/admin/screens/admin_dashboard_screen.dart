import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Dashboard del admin replicado del diseno de Stitch (MotoRide):
/// metricas con cambio %, cards de gestion (User Management, Package
/// Catalog, Reports) y tabla de viajes recientes.
class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'Dashboard Overview',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        const SizedBox(height: 4),
        const Text(
          'Real-time metrics and system health.',
          style: TextStyle(fontSize: 16, color: AppColors.textDim),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Metrica(
                icono: Icons.two_wheeler,
                cambio: '+12% vs last week',
                titulo: 'Total Rides',
                valor: '14,230',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Metrica(
                icono: Icons.account_balance_wallet,
                cambio: '+8% vs last week',
                titulo: 'Total Revenue (Recharges)',
                valor: 'S/ 89,400',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _Metrica(
          icono: Icons.group,
          cambio: 'Live',
          titulo: 'Active Drivers',
          valor: '342',
          esAncho: true,
        ),
        const SizedBox(height: 24),
        const Text(
          'Management',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        const SizedBox(height: 12),
        _CardGestion(icono: Icons.manage_accounts, titulo: 'User Management', subtitulo: 'Riders & Drivers'),
        const SizedBox(height: 10),
        _CardGestion(icono: Icons.inventory_2, titulo: 'Package Catalog', subtitulo: 'Recharge options'),
        const SizedBox(height: 10),
        _CardGestion(icono: Icons.bar_chart, titulo: 'Detailed Reports', subtitulo: 'Analytics & Logs'),
        const SizedBox(height: 24),
        const Text(
          'Recent Rides',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.black),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.line, width: 1),
          ),
          padding: const EdgeInsets.all(16),
          child: const Column(
            children: [
              _FilaViaje(id: '#TRP-9021', pasajero: 'John Doe', conductor: 'Mike R.', monto: 'S/ 12.50', estado: 'En curso', color: AppColors.blue),
              Divider(color: AppColors.line),
              _FilaViaje(id: '#TRP-9020', pasajero: 'Alice Smith', conductor: 'Rosa M.', monto: 'S/ 8.00', estado: 'Completado', color: AppColors.green),
            ],
          ),
        ),
      ],
    );
  }
}

class _Metrica extends StatelessWidget {
  final IconData icono;
  final String cambio;
  final String titulo;
  final String valor;
  final bool esAncho;

  const _Metrica({
    required this.icono,
    required this.cambio,
    required this.titulo,
    required this.valor,
    this.esAncho = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: esAncho ? double.infinity : null,
      padding: const EdgeInsets.all(16),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.yellowSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, size: 18, color: AppColors.black),
              ),
              const Spacer(),
              Text(
                cambio,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.green),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(valor, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.black)),
          const SizedBox(height: 2),
          Text(titulo, style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _CardGestion extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;

  const _CardGestion({required this.icono, required this.titulo, required this.subtitulo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.line, width: 1),
      ),
      child: Row(
        children: [
          Icon(icono, color: AppColors.yellow, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.black)),
                Text(subtitulo, style: const TextStyle(fontSize: 12, color: AppColors.textDim, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.yellow),
        ],
      ),
    );
  }
}

class _FilaViaje extends StatelessWidget {
  final String id;
  final String pasajero;
  final String conductor;
  final String monto;
  final String estado;
  final Color color;

  const _FilaViaje({
    required this.id,
    required this.pasajero,
    required this.conductor,
    required this.monto,
    required this.estado,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.gray,
          child: Text(
            pasajero.split(' ').map((w) => w[0]).take(2).join(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.black),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(id, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDim)),
              Text('$pasajero · $conductor', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.black)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(monto, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.black)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(estado, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
            ),
          ],
        ),
      ],
    );
  }
}
