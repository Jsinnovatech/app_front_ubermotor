import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

/// Status badge pill del design system Kinetic Grid: fondo con tint al 15%
/// del color de estado + texto con el color full-strength.
class EstadoChip extends StatelessWidget {
  final String estado;
  final Color color;

  const EstadoChip({super.key, required this.estado, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.02,
        ),
      ),
    );
  }
}
