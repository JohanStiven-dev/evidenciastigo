class Catalogo {
  final dynamic id;
  final String tipo;
  final String valor;
  final bool? activo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Catalogo({
    required this.id,
    required this.tipo,
    required this.valor,
    this.activo,
    this.createdAt,
    this.updatedAt,
  });

  factory Catalogo.fromJson(Map<String, dynamic> json) {
    return Catalogo(
      id: json['id'],
      tipo: json['tipo'],
      valor: json['valor'],
      activo: json['activo'] ?? true, // Default to true if null
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(), // Default to now if null
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(), // Default to now if null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'valor': valor,
      'activo': activo,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}