import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/dashboard_summary.dart';
import 'package:tigo/models/actividad.dart'; // Import Actividad model
import 'package:fl_chart/fl_chart.dart'; // Import fl_chart
import 'package:tigo/services/api_service.dart';
import 'package:tigo/date_range_picker_popup.dart';
import 'package:tigo/activity_detail_view.dart';
import 'package:tigo/utils/web_utils.dart' if (dart.library.io) 'package:tigo/utils/stub_web_utils.dart'; // Conditional import


class DashboardView extends StatefulWidget {
  final Function(String) onNavigateToActivities;
  const DashboardView({super.key, required this.onNavigateToActivities});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  int _inValidationToday = 0;
  double _evidenceCompletion = 0.0;
  double _budgetExecuted = 0.0;
  double _budgetPlanned = 0.0;
  List<Actividad> _upcomingActivities = [];
  List<Actividad> _recentActivities = []; // New state variable
  DashboardSummary? _dashboardSummary; // Nueva variable de estado
  int _alertasProgramadasSinPresupuesto = 0;
  String _selectedPeriod = '30d'; // To track selected period: '7d', '30d', '90d', 'custom'
  DateTime? _currentStartDate;
  DateTime? _currentEndDate;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData(period: '30d');
  }

  Future<void> _fetchDashboardData({String? period, DateTime? customStartDate, DateTime? customEndDate}) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        if (period != null) {
          _selectedPeriod = period;
        } else if (customStartDate != null && customEndDate != null) {
          _selectedPeriod = 'custom';
        }
      });

      final now = DateTime.now();
      DateTime startDate;
      DateTime endDate = customEndDate ?? DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      if (customStartDate != null) {
        startDate = customStartDate;
      } else if (_selectedPeriod == '7d') {
        startDate = now.subtract(const Duration(days: 7));
      } else if (_selectedPeriod == '90d') {
        startDate = now.subtract(const Duration(days: 90));
      } else { // Default to 30d
        startDate = now.subtract(const Duration(days: 30));
      }

      _currentStartDate = startDate;
      _currentEndDate = endDate;



      // 1. Fetch Summary
      final DashboardSummary? summary = await _apiService.getDashboardSummary(startDate, endDate);
      
      // 2. Fetch Upcoming Activities (Next 30 days)
      final upcomingStartDate = DateTime.now();
      final upcomingEndDate = upcomingStartDate.add(const Duration(days: 30));
      final Map<String, dynamic> upcomingResponse = await _apiService.getActividades(
        startDate: upcomingStartDate,
        endDate: upcomingEndDate,
        sort: 'fecha',
        order: 'asc',
        limit: 10,
      );
      final List<Actividad> upcomingActivities = (upcomingResponse['actividades'] as List)
          .map((e) => e as Actividad)
          .toList();
      
      debugPrint('Dashboard Debug: Upcoming Start Date: $upcomingStartDate');
      debugPrint('Dashboard Debug: Upcoming End Date: $upcomingEndDate');
      debugPrint('Dashboard Debug: Upcoming Response Count: ${upcomingActivities.length}');
      if (upcomingActivities.isNotEmpty) {
        debugPrint('Dashboard Debug: First Upcoming Activity Date: ${upcomingActivities.first.fecha}');
      }

      // 3. Fetch Recent Activities (Created recently)
      final Map<String, dynamic> recentResponse = await _apiService.getActividades(
        sort: 'createdAt',
        order: 'desc',
        limit: 5,
      );
      final List<Actividad> recentActivities = (recentResponse['actividades'] as List)
          .map((e) => e as Actividad)
          .toList();

      if (!mounted) return;

      if (summary != null) {
        _dashboardSummary = summary;

        _inValidationToday = summary.actividadesByStatus
            .firstWhere((item) => item.status == 'En validación', orElse: () => ActivityStatusSummary(status: '', count: 0))
            .count;
        _evidenceCompletion = summary.totalActividades > 0
            ? (summary.actividadesConEvidenciasCompletas / summary.totalActividades) * 100
            : 0.0;
        _budgetExecuted = summary.totalPresupuestoEjecutado;
        _budgetPlanned = summary.totalPresupuestoPlanificado;
        _alertasProgramadasSinPresupuesto = summary.alertasProgramadasSinPresupuesto;
      } else {
        _errorMessage = 'No se pudieron cargar los datos del resumen del dashboard.';
      }

      setState(() {
        _isLoading = false;
        _upcomingActivities = upcomingActivities;
        _recentActivities = recentActivities;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar datos del dashboard: $e';
        _isLoading = false;
        debugPrint('DashboardView: Error in _fetchDashboardData: $e');
      });
    }
  }

  // List<Actividad> allActivities = []; // Removed unused variable

  Future<void> _exportXlsx() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final fileBytes = await _apiService.exportActividadesToXlsx(
        startDate: _currentStartDate,
        endDate: _currentEndDate,
        // Add other filters if needed, e.g., ciudad, canal, status
      );

      if (kIsWeb) {
        exportFileWeb(
          fileBytes,
          'actividades_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        // TODO: Implement file saving for mobile/desktop platforms
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La exportación a Excel no está disponible en la web por ahora.')),
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Excel exportado exitosamente.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar Excel: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: GoogleFonts.inter(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0), // Reduced padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
              'Dashboard Comercial',
              style: GoogleFonts.outfit( // Changed to Outfit
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          const SizedBox(height: 16), // Reduced spacer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0), // Align text with buttons
                child: Text(
                  'Periodo de Análisis:',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildPeriodButton('Últimos 7 Días', '7d'),
                    _buildPeriodButton('Últimos 30 Días', '30d'),
                    _buildPeriodButton('Últimos 90 Días', '90d'),
                    OutlinedButton(
                      onPressed: () async {
                        final DateTimeRange? picked = await showDialog<DateTimeRange>(
                          context: context,
                          builder: (BuildContext context) {
                            return DateRangePickerPopup(
                              initialStartDate: _currentStartDate ?? DateTime.now().subtract(const Duration(days: 7)),
                              initialEndDate: _currentEndDate ?? DateTime.now(),
                            );
                          },
                        );
                        if (picked != null) {
                          _fetchDashboardData(customStartDate: picked.start, customEndDate: picked.end);
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedPeriod == 'custom' ? AppColors.primary : AppColors.textDark,
                        side: BorderSide(color: _selectedPeriod == 'custom' ? AppColors.primary : Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text('Rango Custom', style: GoogleFonts.inter(fontSize: 14)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _exportXlsx,
                      icon: const Icon(Icons.download, size: 16),
                      label: Text('Exportar', style: GoogleFonts.inter(fontSize: 14)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24), // Reduced spacer
          // KPIs
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              int crossAxisCount;
              double childAspectRatio;

              if (width > 1400) {
                crossAxisCount = 4;
                childAspectRatio = 2.0;
              } else if (width > 1100) {
                crossAxisCount = 4;
                childAspectRatio = 1.6;
              } else if (width > 800) {
                crossAxisCount = 2;
                childAspectRatio = 2.5;
              } else if (width > 600) {
                crossAxisCount = 2;
                childAspectRatio = 2.0;
              } else {
                crossAxisCount = 1;
                childAspectRatio = 2.8;
              }

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildKpiCard(
                    context,
                    'Total Actividades',
                    _dashboardSummary!.totalActividades.toString(),
                    '${_dashboardSummary!.variation.totalActividades.toStringAsFixed(1)}% vs per. ant.',
                    _dashboardSummary!.variation.totalActividades >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    Icons.list_alt_outlined,
                  ),
                  _buildKpiCard(
                    context,
                    'En Validación',
                    _inValidationToday.toString(),
                    'Pendientes de Productor',
                    AppColors.textMuted,
                    Icons.hourglass_top_outlined,
                  ),
                  _buildKpiCard(
                    context,
                    '% Evidencias',
                    '${_evidenceCompletion.toStringAsFixed(0)}%',
                    '${_dashboardSummary!.variation.actividadesConEvidenciasCompletas.toStringAsFixed(1)}% vs per. ant.',
                    _dashboardSummary!.variation.actividadesConEvidenciasCompletas >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    Icons.cloud_done_outlined,
                  ),
                  _buildKpiCard(
                    context,
                    'Ejecutado',
                    NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0).format(_budgetExecuted),
                    'Plan: ${NumberFormat.compact(locale: 'es_CO').format(_budgetPlanned)}',
                    _dashboardSummary!.variation.totalPresupuestoEjecutado >= 0 ? Colors.green.shade700 : Colors.red.shade700,
                    Icons.monetization_on_outlined,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12), // Reduced spacer
          _buildAlertsWidget(), // <-- ALERTS WIDGET ADDED HERE
          const SizedBox(height: 12), // Reduced spacer
          // Alerts and Upcoming 7 Days
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1024) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2, // Give more space to chart
                      child: _buildChartPlaceholder(context, _dashboardSummary!),
                    ),
                    const SizedBox(width: 12), // Reduced spacer
                    Expanded(
                      flex: 1, // Give more space to lists
                      child: _buildUpcomingActivities(context),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildChartPlaceholder(context, _dashboardSummary!),
                    const SizedBox(height: 12),
                    _buildUpcomingActivities(context),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 12),
          _buildRecentActivitiesTable(_recentActivities),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesTable(List<Actividad> activities) {
    // Activities are already sorted and limited by API
    final recentActivities = activities;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividades Recientes',
              style: GoogleFonts.outfit( // Changed to Outfit
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            if (recentActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No hay actividades recientes para mostrar.',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Column(
                children: recentActivities.map((activity) => _buildRecentActivityItem(activity)).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityItem(Actividad activity) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), // Reduced padding
        tileColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        leading: _buildStatusBadge(activity.status),
        title: Text(
          activity.codigos,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${activity.puntoVenta}, ${activity.ciudad}',
          style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, size: 14),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ActivityDetailView(actividad: activity),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Programada':
        bgColor = AppColors.statusProgramadaBg;
        textColor = AppColors.statusProgramadaText;
        break;
      case 'En ejecución':
      case 'En Curso':
        bgColor = AppColors.statusEjecucionBg;
        textColor = AppColors.statusEjecucionText;
        break;
      case 'Finalizada':
      case 'Cerrada':
        bgColor = AppColors.statusCerradaBg;
        textColor = AppColors.statusCerradaText;
        break;
      case 'En validación':
      case 'En Revisión':
        bgColor = AppColors.statusEnValidacionBg;
        textColor = AppColors.statusEnValidacionText;
        break;
      case 'Planificación':
      case 'Registrada':
        bgColor = AppColors.statusRegistradaBg;
        textColor = AppColors.statusRegistradaText;
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor == Colors.white ? Colors.grey.shade200 : Colors.transparent),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String text, String period) {
    bool isSelected = _selectedPeriod == period;
    return isSelected
        ? ElevatedButton(
            onPressed: () => _fetchDashboardData(period: period),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(text, style: GoogleFonts.inter(fontSize: 14)),
          )
        : OutlinedButton(
            onPressed: () => _fetchDashboardData(period: period),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textDark,
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(text, style: GoogleFonts.inter(fontSize: 14)),
          );
  }

  Widget _buildAlertsWidget() {
    if (_alertasProgramadasSinPresupuesto == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAEB), // Warning 50
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFEF0C7)), // Warning 100
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF0C7), // Warning 100
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC6803), size: 20), // Warning 600
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Atención Requerida',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB54708), // Warning 700
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Hay $_alertasProgramadasSinPresupuesto actividades programadas sin presupuesto asignado.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFFB54708),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () {
              widget.onNavigateToActivities('Programada');
            },
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB54708),
              textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            child: const Text('Ver Actividades'),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
      BuildContext context, String title, String value, String subtitle, Color trendColor, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEAECF0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(icon, size: 20, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  trendColor == Colors.green.shade700 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 14,
                  color: trendColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: trendColor,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(BuildContext context, DashboardSummary summary) {
    final List<Color> pieColors = [
      AppColors.primary,
      AppColors.primaryLight,
      AppColors.secondary,
      AppColors.textMuted,
      Colors.blue.shade200,
      Colors.grey.shade400,
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actividades por Estado',
              style: GoogleFonts.outfit( // Changed to Outfit
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            if (summary.actividadesByStatus.isEmpty)
              SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    'No hay actividades para mostrar.',
                    style: GoogleFonts.inter(color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: summary.actividadesByStatus.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      return PieChartSectionData(
                        color: pieColors[index % pieColors.length],
                        value: data.count.toDouble(),
                        title: '${data.count}',
                        radius: 50,
                        titleStyle: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(enabled: false),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Legend
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: summary.actividadesByStatus.asMap().entries.map((entry) {
                final index = entry.key;
                final data = entry.value;
                final Color color = pieColors[index % pieColors.length];
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data.status,
                      style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingActivities(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📅 Próximas 7 Días',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            if (_upcomingActivities.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No hay actividades próximas.',
                    style: GoogleFonts.inter(color: AppColors.textMuted),
                  ),
                ),
              )
            else
              Column(
                children: _upcomingActivities.take(5).map((activity) => _buildUpcomingActivityItem(
                      activity.codigos,
                      '${activity.puntoVenta}, ${activity.ciudad} (${DateFormat('MMM d').format(activity.fecha)})',
                      activity.status == 'Programada' ? AppColors.primary : Colors.orange,
                    )).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildUpcomingActivityItem(String prefix, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(8.0), // Reduced padding
        decoration: BoxDecoration(
          color: color.withOpacitySafe(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(left: BorderSide(color: color, width: 4)),
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$prefix: ',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: color,
                  fontSize: 12,
                ),
              ),
              TextSpan(
                text: text,
                style: GoogleFonts.inter(
                  color: AppColors.textDark,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}