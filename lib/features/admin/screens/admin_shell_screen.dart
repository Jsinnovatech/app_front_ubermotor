import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';
import 'gestion_paquetes_screen.dart';

/// Shell del administrador: 2 pestanas (Dashboard y Gestion de paquetes).
/// super_admin ve todo; admin opera su zona. Mismo patron que Comanda.
class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pantallas = [const AdminDashboardScreen(), const GestionPaquetesScreen()];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin · ${auth.sesion?.nombre ?? ''}'),
        actions: [
          IconButton(
            tooltip: 'Salir',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().cerrarSesion(),
          ),
        ],
      ),
      body: pantallas[_tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.bar_chart), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.settings), label: 'Paquetes'),
        ],
      ),
    );
  }
}
