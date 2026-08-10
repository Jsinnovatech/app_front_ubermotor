import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation_service.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/conductor_provider.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/conductor/screens/conductor_home_screen.dart';
import 'features/cliente/screens/cliente_home_screen.dart';
import 'features/admin/screens/admin_shell_screen.dart';

void main() {
  runApp(const HablaVasApp());
}

class HablaVasApp extends StatelessWidget {
  const HablaVasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ConductorProvider()),
      ],
      child: MaterialApp(
        title: 'HablaVas',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        home: const _Portero(),
      ),
    );
  }
}

/// Decide que pantalla mostrar segun el estado de sesion y el tipo de perfil.
/// Unico lugar de la app que sabe "que rol ve que home" (patron Comanda).
class _Portero extends StatelessWidget {
  const _Portero();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!auth.autenticado) {
      return const LoginScreen();
    }

    switch (auth.tipoUsuario) {
      case 'conductor':
        return const ConductorHomeScreen();
      case 'cliente':
        return const ClienteHomeScreen();
      case 'administrador':
        return const AdminShellScreen();
      default:
        return Scaffold(body: Center(child: Text('Rol desconocido: ${auth.tipoUsuario}')));
    }
  }
}
