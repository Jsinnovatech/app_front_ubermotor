import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/conductor_service.dart';
import '../widgets/tarjeta_subida_documento.dart';

/// Registro del conductor en 5 TABS rectangulares (formulario epico):
/// 1. Datos -> nombre, correo, contraseña, repetir contraseña
/// 2. DNI -> frente + dorso
/// 3. Brevete -> frente + dorso
/// 4. SOAT -> foto del SOAT
/// 5. Moto -> 3 fotos de la moto
/// Usa PageView con keepAlive para que las fotos subidas NO se pierdan al
/// cambiar de pestaña. Tras completar, vuelve al login.
class RegistroConductorMultipaso extends StatefulWidget {
  const RegistroConductorMultipaso({super.key});

  @override
  State<RegistroConductorMultipaso> createState() => _RegistroConductorMultipasoState();
}

class _RegistroConductorMultipasoState extends State<RegistroConductorMultipaso> {
  final PageController _pageController = PageController();
  int _paso = 0;
  bool _cargando = false;
  bool _cuentaCreada = false;
  String? _error;

  // Tab 1: datos
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _password2 = TextEditingController();
  bool _ocultarPassword = true;
  bool _ocultarPassword2 = true;

  static const _tabs = ['Datos', 'DNI', 'Brevete', 'SOAT', 'Moto'];

  @override
  void dispose() {
    _pageController.dispose();
    _nombre.dispose();
    _email.dispose();
    _password.dispose();
    _password2.dispose();
    super.dispose();
  }

  void _ir(int indice) {
    if (indice > 0 && !_cuentaCreada) {
      setState(() => _error = 'Primero crea tu cuenta en el paso 1');
      return;
    }
    if (indice < 0) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.animateToPage(
      indice,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _crearCuenta() async {
    if (_password.text.length < 8) {
      setState(() => _error = 'La contraseña debe tener mínimo 8 caracteres');
      return;
    }
    if (_password.text != _password2.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().registrar(
            email: _email.text.trim(),
            password: _password.text,
            nombre: _nombre.text.trim(),
            tipoUsuario: 'conductor',
          );
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _cuentaCreada = true;
      });
      _ir(1);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = e.toString().replaceFirst('ApiException(', '').replaceFirst(')', '');
      });
    }
  }

  void _terminar() {
    context.read<AuthProvider>().cerrarSesion();
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.yellow),
          onPressed: () => _ir(_paso - 1),
        ),
        title: const Text(
          'Registro de Conductor',
          style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.yellow, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          // Tabs rectangulares horizontales
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: SizedBox(
              height: 54,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    _tab(i),
                    if (i < _tabs.length - 1) const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          // PageView con keepAlive: las fotos no se pierden al cambiar de tab
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: _cuentaCreada ? const NeverScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _paso = i),
              children: [
                _KeepAlive(child: _tabDatos()),
                _KeepAlive(child: _tabDni()),
                _KeepAlive(child: _tabBrevete()),
                _KeepAlive(child: _tabSoat()),
                _KeepAlive(child: _tabMoto()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tab(int indice) {
    final activo = _paso == indice;
    return GestureDetector(
      onTap: () => _ir(indice),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: activo ? AppColors.black : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: activo ? AppColors.black : AppColors.line, width: 1.5),
        ),
        child: Center(
          child: Text(
            _tabs[indice],
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 14,
              color: activo ? AppColors.yellow : AppColors.textDim,
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabDatos() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.asset('logo_icons/logo.webp', width: 100, height: 100, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bienvenido a HablaVas',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.black),
          ),
          const SizedBox(height: 4),
          const Text(
            'Regístrate como conductor y empieza a ganar.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textDim),
          ),
          const SizedBox(height: 24),
          _campo(_nombre, 'Nombre completo', Icons.person),
          const SizedBox(height: 14),
          _campo(_email, 'Correo electrónico', Icons.email),
          const SizedBox(height: 14),
          _campo(
            _password,
            'Contraseña (mín. 8 caracteres)',
            Icons.lock,
            oculto: _ocultarPassword,
            sufijo: IconButton(
              icon: Icon(_ocultarPassword ? Icons.visibility : Icons.visibility_off, color: AppColors.textDim),
              onPressed: () => setState(() => _ocultarPassword = !_ocultarPassword),
            ),
          ),
          const SizedBox(height: 14),
          _campo(
            _password2,
            'Repetir contraseña',
            Icons.lock_outline,
            oculto: _ocultarPassword2,
            sufijo: IconButton(
              icon: Icon(_ocultarPassword2 ? Icons.visibility : Icons.visibility_off, color: AppColors.textDim),
              onPressed: () => setState(() => _ocultarPassword2 = !_ocultarPassword2),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.yellow,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _cargando ? null : _crearCuenta,
              child: Text(
                _cargando ? 'Creando cuenta...' : 'CONTINUAR → DNI',
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabDni() {
    return _tabDocumentos([
      ('dni', 'frente', 'DNI — Frente', Icons.badge),
      ('dni', 'dorso', 'DNI — Dorso', Icons.badge_outlined),
    ], 'DNI', 1);
  }

  Widget _tabBrevete() {
    return _tabDocumentos([
      ('brevete', 'frente', 'Brevete — Frente', Icons.card_membership),
      ('brevete', 'dorso', 'Brevete — Dorso', Icons.card_membership_outlined),
    ], 'Brevete', 2);
  }

  Widget _tabSoat() {
    return _tabDocumentos([
      ('soat', null, 'SOAT', Icons.verified_user),
    ], 'SOAT', 3);
  }

  Widget _tabMoto() {
    return _tabDocumentos([
      ('moto', null, 'Foto Moto 1', Icons.two_wheeler),
      ('moto', null, 'Foto Moto 2', Icons.two_wheeler_outlined),
      ('moto', null, 'Foto Moto 3', Icons.two_wheeler),
    ], 'Moto', 4);
  }

  /// Tarjetas de ancho completo (una por fila) + botones atras/siguiente.
  Widget _tabDocumentos(List<(String, String?, String, IconData)> docs, String titulo, int indice) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
          child: Text(
            'Sube las fotos de $titulo tocando cada tarjeta. Un administrador las revisará.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.black),
          ),
        ),
        const SizedBox(height: 16),
        for (final (tipo, cara, label, icono) in docs) ...[
          TarjetaSubidaDocumento(
            key: ValueKey('$tipo-${cara ?? ''}-$label'),
            etiqueta: label,
            icono: icono,
            alSubir: (bytes, nombre) async {
              await ConductorService.subirDocumento(tipo: tipo, cara: cara, bytes: bytes, nombreArchivo: nombre);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        if (_error != null) ...[
          Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
        ],
        // Botones Anterior / Siguiente o Terminar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.black,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _ir(indice - 1),
                  child: const Text('← Atrás', style: TextStyle(fontWeight: FontWeight.w900)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: SizedBox(
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.black,
                    foregroundColor: AppColors.yellow,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    if (indice < 4) {
                      _ir(indice + 1);
                    } else {
                      _terminar();
                    }
                  },
                  child: Text(
                    indice < 4 ? 'SIGUIENTE →' : 'TERMINAR — Volver al login',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _campo(TextEditingController c, String label, IconData icono, {bool oculto = false, Widget? sufijo}) {
    return TextField(
      controller: c,
      obscureText: oculto,
      style: const TextStyle(color: AppColors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textDim, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icono, color: AppColors.textDim),
        suffixIcon: sufijo,
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

/// Mantiene vivo el estado de cada pagina del PageView (las fotos no se
/// pierden al cambiar de pestaña).
class _KeepAlive extends StatefulWidget {
  final Widget child;
  const _KeepAlive({required this.child});

  @override
  State<_KeepAlive> createState() => _KeepAliveState();
}

class _KeepAliveState extends State<_KeepAlive> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
