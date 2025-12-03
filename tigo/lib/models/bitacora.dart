class Bitacora {
  final int id;
  final String? accion;
  final String? desdeEstado;
  final String? haciaEstado;
  final String? motivo;
  final DateTime fecha;
  final String usuario;

  Bitacora({
    required this.id,
    this.accion,
    this.desdeEstado,
    this.haciaEstado,
    this.motivo,
    required this.fecha,
    required this.usuario,
  });

  factory Bitacora.fromJson(Map<String, dynamic> json) {
    return Bitacora(
      id: json['id'],
      accion: json['accion'],
      desdeEstado: json['desde_estado'],
      haciaEstado: json['hacia_estado'],
      motivo: json['motivo'],
      fecha: DateTime.parse(json['createdAt']), // Use createdAt from timestamps
      usuario: json['User'] != null ? json['User']['nombre'] : 'Usuario desconocido',
    );
  }
}
