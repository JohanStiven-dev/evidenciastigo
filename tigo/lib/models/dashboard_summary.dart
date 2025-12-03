class DashboardSummary {
  final List<ActivityStatusSummary> actividadesByStatus;
  final int totalActividades;
  final double totalPresupuestoEjecutado;
  final double totalPresupuestoPlanificado;
  final int actividadesConEvidenciasCompletas;
  final int alertasProgramadasSinPresupuesto;
  final Breakdown breakdown;
  final Variation variation;

  DashboardSummary({
    required this.actividadesByStatus,
    required this.totalActividades,
    required this.totalPresupuestoEjecutado,
    required this.totalPresupuestoPlanificado,
    required this.actividadesConEvidenciasCompletas,
    required this.alertasProgramadasSinPresupuesto,
    required this.breakdown,
    required this.variation,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    var statusList = json['actividadesByStatus'] as List;
    List<ActivityStatusSummary> statusSummaryList = statusList.map((i) => ActivityStatusSummary.fromJson(i)).toList();

    return DashboardSummary(
      actividadesByStatus: statusSummaryList,
      totalActividades: json['totalActividades'],
      totalPresupuestoEjecutado: (json['totalPresupuestoEjecutado'] as num).toDouble(),
      totalPresupuestoPlanificado: (json['totalPresupuestoPlanificado'] as num).toDouble(),
      actividadesConEvidenciasCompletas: json['actividadesConEvidenciasCompletas'],
      alertasProgramadasSinPresupuesto: json['alertasProgramadasSinPresupuesto'],
      breakdown: Breakdown.fromJson(json['breakdown']),
      variation: Variation.fromJson(json['variation']),
    );
  }
}

class ActivityStatusSummary {
  final String status;
  final int count;

  ActivityStatusSummary({required this.status, required this.count});

  factory ActivityStatusSummary.fromJson(Map<String, dynamic> json) {
    return ActivityStatusSummary(
      status: json['status'],
      count: json['count'],
    );
  }
}

class Breakdown {
  final int today;
  final int thisWeek;
  final int thisMonth;

  Breakdown({required this.today, required this.thisWeek, required this.thisMonth});

  factory Breakdown.fromJson(Map<String, dynamic> json) {
    return Breakdown(
      today: json['today'],
      thisWeek: json['thisWeek'],
      thisMonth: json['thisMonth'],
    );
  }
}

class Variation {
  final double totalActividades;
  final double totalPresupuestoEjecutado;
  final double actividadesConEvidenciasCompletas;

  Variation({
    required this.totalActividades,
    required this.totalPresupuestoEjecutado,
    required this.actividadesConEvidenciasCompletas,
  });

  factory Variation.fromJson(Map<String, dynamic> json) {
    return Variation(
      totalActividades: (json['totalActividades'] as num).toDouble(),
      totalPresupuestoEjecutado: (json['totalPresupuestoEjecutado'] as num).toDouble(),
      actividadesConEvidenciasCompletas: (json['actividadesConEvidenciasCompletas'] as num).toDouble(),
    );
  }
}