class Proyecto {
  final int id;
  final String nombre;
  final int? clienteId;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? estado;
  final DateTime createdAt;
  final DateTime updatedAt;

  Proyecto({
    required this.id,
    required this.nombre,
    this.clienteId,
    this.fechaInicio,
    this.fechaFin,
    this.estado,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Proyecto.fromJson(Map<String, dynamic> json) {
    return Proyecto(
      id: json['id'],
      nombre: json['nombre'],
      clienteId: json['cliente_id'],
      fechaInicio: json['fecha_inicio'] != null ? DateTime.parse(json['fecha_inicio']) : null,
      fechaFin: json['fecha_fin'] != null ? DateTime.parse(json['fecha_fin']) : null,
      estado: json['estado'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'cliente_id': clienteId,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'estado': estado,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}