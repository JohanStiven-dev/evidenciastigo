class User {
  final int id;
  final String nombre;
  final String email;
  final String rol;
  final String? telefono;
  final bool? estado; // Hacemos opcional
  final DateTime? createdAt; // Hacemos opcional
  final DateTime? updatedAt; // Hacemos opcional

  User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rol,
    this.telefono,
    this.estado, // Ya no es required
    this.createdAt, // Ya no es required
    this.updatedAt, // Ya no es required
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nombre: json['nombre'],
      email: json['email'],
      rol: json['rol'],
      telefono: json['telefono'],
      estado: json['estado'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rol': rol,
      'telefono': telefono,
      'estado': estado,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}