class Evidencia {
  final int id;
  final int presupuestoItemId;
  final String nombre;
  final String url;
  final String tipo;
  final String? comentario;
  final String status;

  Evidencia({
    required this.id,
    required this.presupuestoItemId,
    required this.nombre,
    required this.url,
    required this.tipo,
    this.comentario,
    required this.status,
  });

  factory Evidencia.fromJson(Map<String, dynamic> json) {
    const String baseUrl = 'http://localhost:3000/api/v2';
    final String finalUrl = '$baseUrl/evidencias/${json['id']}/download';

    return Evidencia(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      presupuestoItemId: json['presupuesto_item_id'] is int 
          ? json['presupuesto_item_id'] 
          : int.parse(json['presupuesto_item_id'].toString()),
      nombre: json['archivo_nombre'] ?? 'Sin nombre',
      url: finalUrl,
      tipo: json['tipo'] ?? 'otro',
      comentario: json['comentario'],
      status: json['status'] ?? 'pendiente',
    );
  }
}

