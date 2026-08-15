import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/navigation_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/conductor_provider.dart';
import 'providers/cliente_provider.dart';
import 'providers/autoridad_provider.dart';

import 'features/auth/screens/login_screen.dart';
import 'features/conductor/screens/conductor_home_screen.dart';
import 'features/conductor/screens/validacion_pendiente_screen.dart';
import 'features/cliente/screens/cliente_home_screen.dart';
import 'features/admin/screens/admin_shell_screen.dart';
import 'features/autoridad/screens/autoridad_home_screen.dart';
import 'services/onesignal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.inicializar();
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
        ChangeNotifierProvider(create: (_) => ClienteProvider()),
        ChangeNotifierProvider(create: (_) => AutoridadProvider()),
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
        return const _ConductorShell();
      case 'cliente':
        return const ClienteHomeScreen();
      case 'administrador':
        return const AdminShellScreen();
      case 'serenazgo':
      case 'policia':
        return AutoridadHomeScreen(rol: auth.tipoUsuario!);
      default:
        return Scaffold(body: Center(child: Text('Rol desconocido: ${auth.tipoUsuario}')));
    }
  }
}

/// Shell del conductor: carga su perfil y decide si va al Home (aprobado) o
/// a la pantalla de validacion (pendiente de aprobacion del admin).
class _ConductorShell extends StatefulWidget {
  const _ConductorShell();

  @override
  State<_ConductorShell> createState() => _ConductorShellState();
}

class _ConductorShellState extends State<_ConductorShell> {
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<ConductorProvider>();
      await provider.cargarPerfil();
      if (mounted) setState(() => _cargando = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.yellow)));
    }
    final conductor = context.watch<ConductorProvider>().perfil;
    final aprobado = conductor?.aprobado ?? false;
    if (!aprobado) {
      return const ValidacionPendienteScreen();
    }
    return const ConductorHomeScreen();
  }
}
