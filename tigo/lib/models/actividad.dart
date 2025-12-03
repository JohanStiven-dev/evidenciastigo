class Actividad {
  final int id;
  final int? proyectoId;
  final int comercialId;
  final int? productorId;
  final String agencia;
  final String codigos;
  final String semana;
  final String responsableActividad;
  final String segmento;
  final String clasePpto;
  final String canal;
  final String ciudad;
  final String puntoVenta;
  final String direccion;
  final DateTime fecha;
  final String horaInicio;
  final String horaFin;
  final String status;
  final String? subStatus;
  final double valorTotal; // New field
  final String? responsableCanal;
  final String? celularResponsable;
  final String? recursosAgencia;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Presupuesto? presupuesto;

  Actividad({
    required this.id,
    this.proyectoId,
    required this.comercialId,
    this.productorId,
    required this.agencia,
    required this.codigos,
    required this.semana,
    required this.responsableActividad,
    required this.segmento,
    required this.clasePpto,
    required this.canal,
    required this.ciudad,
    required this.puntoVenta,
    required this.direccion,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    required this.status,
    this.subStatus,
    required this.valorTotal, // New field
    this.responsableCanal,
    this.celularResponsable,
    this.recursosAgencia,
    required this.createdAt,
    required this.updatedAt,
    this.presupuesto,
  });

  Actividad copyWith({
    int? id,
    int? proyectoId,
    int? comercialId,
    int? productorId,
    String? agencia,
    String? codigos,
    String? semana,
    String? responsableActividad,
    String? segmento,
    String? clasePpto,
    String? canal,
    String? ciudad,
    String? puntoVenta,
    String? direccion,
    DateTime? fecha,
    String? horaInicio,
    String? horaFin,
    String? status,
    String? subStatus,
    double? valorTotal, // New field
    String? responsableCanal,
    String? celularResponsable,
    String? recursosAgencia,
    DateTime? createdAt,
    DateTime? updatedAt,
    Presupuesto? presupuesto,
  }) {
    return Actividad(
      id: id ?? this.id,
      proyectoId: proyectoId ?? this.proyectoId,
      comercialId: comercialId ?? this.comercialId,
      productorId: productorId ?? this.productorId,
      agencia: agencia ?? this.agencia,
      codigos: codigos ?? this.codigos,
      semana: semana ?? this.semana,
      responsableActividad: responsableActividad ?? this.responsableActividad,
      segmento: segmento ?? this.segmento,
      clasePpto: clasePpto ?? this.clasePpto,
      canal: canal ?? this.canal,
      ciudad: ciudad ?? this.ciudad,
      puntoVenta: puntoVenta ?? this.puntoVenta,
      direccion: direccion ?? this.direccion,
      fecha: fecha ?? this.fecha,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      status: status ?? this.status,
      subStatus: subStatus ?? this.subStatus,
      valorTotal: valorTotal ?? this.valorTotal, // New field
      responsableCanal: responsableCanal ?? this.responsableCanal,
      celularResponsable: celularResponsable ?? this.celularResponsable,
      recursosAgencia: recursosAgencia ?? this.recursosAgencia,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      presupuesto: presupuesto ?? this.presupuesto,
    );
  }

  factory Actividad.fromJson(Map<String, dynamic> json) {
    return Actividad(
      id: json['id'] ?? 0,
      proyectoId: json['proyecto_id'],
      comercialId: json['comercial_id'] ?? 0,
      productorId: json['productor_id'],
      agencia: json['agencia'] ?? '',
      codigos: json['codigos'] ?? '',
      semana: json['semana'] ?? '',
      responsableActividad: json['responsable_actividad'] ?? '',
      segmento: json['segmento'] ?? '',
      clasePpto: json['clase_ppto'] ?? '',
      canal: json['canal'] ?? '',
      ciudad: json['ciudad'] ?? '',
      puntoVenta: json['punto_venta'] ?? '',
      direccion: json['direccion'] ?? '',
      fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : DateTime.now(),
      horaInicio: json['hora_inicio'] ?? '',
      horaFin: json['hora_fin'] ?? '',
      status: json['status'] ?? 'Desconocido',
      subStatus: json['sub_status'],
      valorTotal: _parseDynamicToDouble(json['valor_total']), // New field
      responsableCanal: json['responsable_canal'],
      celularResponsable: json['celular_responsable'],
      recursosAgencia: json['recursos_agencia'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      presupuesto: json['Presupuesto'] != null ? Presupuesto.fromJson(json['Presupuesto']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'proyecto_id': proyectoId,
      'comercial_id': comercialId,
      'productor_id': productorId,
      'agencia': agencia,
      'codigos': codigos,
      'semana': semana,
      'responsable_actividad': responsableActividad,
      'segmento': segmento,
      'clase_ppto': clasePpto,
      'canal': canal,
      'ciudad': ciudad,
      'punto_venta': puntoVenta,
      'direccion': direccion,
      'fecha': fecha.toIso8601String().split('T')[0], // Date only
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'status': status,
      'sub_status': subStatus,
      'valor_total': valorTotal, // New field
      'responsable_canal': responsableCanal,
      'celular_responsable': celularResponsable,
      'recursos_agencia': recursosAgencia,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

double _parseDynamicToDouble(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value) ?? 0.0;
  }
  return 0.0;
}

class Presupuesto {
  final int id;
  final double subtotal;
  final double ivaPorcentaje;
  final double ivaValor;
  final double totalCop;
  final String? archivoOc;
  final List<PresupuestoItem> items;

  Presupuesto({
    required this.id,
    required this.subtotal,
    required this.ivaPorcentaje,
    required this.ivaValor,
    required this.totalCop,
    this.archivoOc,
    required this.items,
  });

  factory Presupuesto.fromJson(Map<String, dynamic> json) {
    var itemsList = json['PresupuestoItems'] as List? ?? [];
    List<PresupuestoItem> presupuestoItems = itemsList.map((i) => PresupuestoItem.fromJson(i)).toList();

    return Presupuesto(
      id: json['id'],
      subtotal: _parseDynamicToDouble(json['subtotal']),
      ivaPorcentaje: _parseDynamicToDouble(json['iva_porcentaje']),
      ivaValor: _parseDynamicToDouble(json['iva_valor']),
      totalCop: _parseDynamicToDouble(json['total_cop']),
      archivoOc: json['archivo_oc'],
      items: presupuestoItems,
    );
  }
}

class PresupuestoItem {
  final int id;
  final String item;
  final int cantidad;
  final double costoUnitario;
  final double costoTotal;
  final String? comentario;

  PresupuestoItem({
    required this.id,
    required this.item,
    required this.cantidad,
    required this.costoUnitario,
    required this.costoTotal,
    this.comentario,
  });

  factory PresupuestoItem.fromJson(Map<String, dynamic> json) {
    return PresupuestoItem(
      id: json['id'],
      item: json['item'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      costoUnitario: _parseDynamicToDouble(json['costo_unitario_cop']),
      costoTotal: _parseDynamicToDouble(json['subtotal_cop']),
      comentario: json['comentario'],
    );
  }
}