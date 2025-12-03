class Notificacion {
  final int id;
  final int userId;
  final int? actividadId;
  final String tipoEvento;
  final String canal;
  final Map<String, dynamic>? payload;
  final DateTime? enviadoAt;
  final String estado;
  final DateTime createdAt;

  Notificacion({
    required this.id,
    required this.userId,
    this.actividadId,
    required this.tipoEvento,
    required this.canal,
    this.payload,
    this.enviadoAt,
    required this.estado,
    required this.createdAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: json['id'],
      userId: json['user_id'],
      actividadId: json['actividad_id'],
      tipoEvento: json['tipo_evento'] ?? '',
      canal: json['canal'] ?? '',
      payload: json['payload'] != null ? Map<String, dynamic>.from(json['payload']) : null,
      enviadoAt: json['enviado_at'] != null ? DateTime.parse(json['enviado_at']) : null,
      estado: json['estado'] ?? 'desconocido',
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}