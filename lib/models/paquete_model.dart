class Paquete {
  final int id;
  final String nombre;
  final int monto; // soles: 2 / 4 / 8
  final int carreras; // 5 / 10 / 20

  Paquete({required this.id, required this.nombre, required this.monto, required this.carreras});

  factory Paquete.desdeJson(Map<String, dynamic> json) {
    return Paquete(
      id: json['id'],
      nombre: json['nombre'],
      monto: json['monto'],
      carreras: json['carreras'],
    );
  }
}
