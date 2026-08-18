import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Campo numerico de oferta con prefijo 'S/ ' y botones - / + (patron InDrive).
/// Minimo S/ 3.00, maximo S/ 50.00, paso de S/ 0.50. Reporta el valor por
/// [onCambio] y tambien via [valor]. Se usa en el panel de carrera nueva y en
/// el dialogo de oferta.
class CampoOferta extends StatefulWidget {
  final double inicial;
  final double minimo;
  final double maximo;
  final double paso;
  final ValueChanged<double>? onCambio;

  const CampoOferta({
    super.key,
    this.inicial = 3.0,
    this.minimo = 3.0,
    this.maximo = 50.0,
    this.paso = 0.5,
    this.onCambio,
  });

  @override
  State<CampoOferta> createState() => _CampoOfertaState();
}

class _CampoOfertaState extends State<CampoOferta> {
  late final TextEditingController _controlador;
  late double _valor;

  @override
  void initState() {
    super.initState();
    _valor = widget.inicial;
    _controlador = TextEditingController(text: _valor.toStringAsFixed(2));
    _controlador.addListener(_onTextoManual);
  }

  @override
  void dispose() {
    _controlador.dispose();
    super.dispose();
  }

  void _onTextoManual() {
    final texto = _controlador.text.replaceAll(',', '.').trim();
    final valor = double.tryParse(texto);
    if (valor != null) {
      final nuevo = _clamp(valor);
      _valor = nuevo;
      widget.onCambio?.call(nuevo);
    }
  }

  double _clamp(double valor) {
    if (valor < widget.minimo) return widget.minimo;
    if (valor > widget.maximo) return widget.maximo;
    return (valor * 100).round() / 100;
  }

  void _cambiar(double delta) {
    final nuevo = _clamp(_valor + delta);
    setState(() {
      _valor = nuevo;
      _controlador.text = nuevo.toStringAsFixed(2);
    });
    widget.onCambio?.call(nuevo);
  }

  double get valor => _valor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _boton(Icons.remove, onTap: () => _cambiar(-widget.paso)),
        Expanded(
          child: TextField(
            controller: _controlador,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.black),
            decoration: const InputDecoration(
              prefixText: 'S/ ',
              border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(4))),
            ),
          ),
        ),
        _boton(Icons.add, onTap: () => _cambiar(widget.paso)),
      ],
    );
  }

  Widget _boton(IconData icono, {required VoidCallback onTap}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.line),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 20,
        icon: Icon(icono, color: AppColors.black),
        onPressed: onTap,
      ),
    );
  }
}
