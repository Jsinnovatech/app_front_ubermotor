import 'package:flutter/material.dart';

/// Paleta oficial de UberMotor: extraida del design system que aprobamos en
/// Stitch (MotoRide Prepago App). No inventar tonos nuevos.
class AppColors {
  static const Color yellow = Color(0xFFF5B800);
  static const Color yellowSoft = Color(0xFFFFF3D1);
  static const Color black = Color(0xFF141414);
  static const Color gray = Color(0xFFF5F5F2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF22A45D);
  static const Color greenSoft = Color(0xFFE8F6EE);
  static const Color red = Color(0xFFE5484D);
  static const Color redSoft = Color(0xFFFDE8E9);
  static const Color blue = Color(0xFF007AFF);

  static const Color textDim = Color(0xFF888888);
  static const Color line = Color(0xFFE0E0E0); // borde de cards (Kinetic Grid)
  static const Color placeholder = Color(0xFF757575);

  // Estados de viaje (mismos nombres que el backend, sin traducir)
  static const Color solicitado = yellow;
  static const Color asignado = blue;
  static const Color enCurso = blue;
  static const Color completado = green;
  static const Color cancelado = red;
  static const Color rechazado = red;

  static Color azulEstado(String estado) {
    switch (estado) {
      case 'completado':
        return completado;
      case 'cancelado':
      case 'rechazado':
        return cancelado;
      case 'en_curso':
      case 'asignado':
        return enCurso;
      case 'solicitado':
      default:
        return solicitado;
    }
  }
}
