import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/actividad.dart';
import 'package:tigo/models/evidencia.dart';
import 'package:tigo/services/api_service.dart';
import 'package:tigo/activity_detail_view.dart';

class CalendarioView extends StatefulWidget {
  const CalendarioView({super.key});

  @override
  State<CalendarioView> createState() => _CalendarioViewState();
}

class _CalendarioViewState extends State<CalendarioView> {
  final ApiService _apiService = ApiService();
  late Future<List<Actividad>> _actividadesFuture;
  List<Actividad> _allActivities = [];
  Map<DateTime, List<Actividad>> _events = {};
  
  // ignore: prefer_final_fields
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _actividadesFuture = _fetchActivities();
  }

  Future<List<Actividad>> _fetchActivities() async {
    try {
      // Fetch all activities without pagination
      final response = await _apiService.getActividades(limit: 1000); 
      _allActivities = response['actividades'];
      _groupEvents();
      return _allActivities;
    } catch (e) {
      debugPrint('Error fetching activities for calendar: $e');
      return [];
    }
  }

  void _groupEvents() {
    _events = {};
    for (var activity in _allActivities) {
      // Normalize date to UTC midnight for TableCalendar
      final date = DateTime.utc(activity.fecha.year, activity.fecha.month, activity.fecha.day);
      if (_events[date] == null) {
        _events[date] = [];
      }
      _events[date]!.add(activity);
    }
  }

  List<Actividad> _getEventsForDay(DateTime day) {
    // TableCalendar passes UTC dates if configured correctly, but let's be safe
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  Color _getColorForStatus(String? status) {
    switch (status) {
      case 'Planificación': return AppColors.statusRegistradaText;
      case 'Confirmada': return AppColors.statusProgramadaText;
      case 'En Curso': return AppColors.statusEjecucionText;
      case 'Finalizada': return AppColors.statusCerradaText;
      default: return Colors.grey;
    }
  }

  Color _getBgColorForStatus(String? status) {
    switch (status) {
      case 'Planificación': return AppColors.statusRegistradaBg;
      case 'Confirmada': return AppColors.statusProgramadaBg;
      case 'En Curso': return AppColors.statusEjecucionBg;
      case 'Finalizada': return AppColors.statusCerradaBg;
      default: return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Calendario de Actividades',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.textDark),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: FutureBuilder<List<Actividad>>(
        future: _actividadesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar actividades: ${snapshot.error}'));
          }

          return Column(
            children: [
              _buildCalendar(),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacitySafe(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Agenda del Día',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                            Text(
                              DateFormat('EEEE, d MMMM', 'es').format(_selectedDay ?? DateTime.now()),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: _buildEventList()),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacitySafe(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<Actividad>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          titleCentered: true,
          formatButtonVisible: false,
          titleTextStyle: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          leftChevronIcon: const Icon(Icons.chevron_left, color: AppColors.primary),
          rightChevronIcon: const Icon(Icons.chevron_right, color: AppColors.primary),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: GoogleFonts.inter(color: Colors.red.shade300),
          defaultTextStyle: GoogleFonts.inter(color: AppColors.textDark),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacitySafe(0.2),
            shape: BoxShape.circle,
          ),
          todayTextStyle: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.secondary,
            shape: BoxShape.circle,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarBuilders: CalendarBuilders(
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return null;
            return Positioned(
              bottom: 1,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((event) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _getColorForStatus(event.status),
                      shape: BoxShape.circle,
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList() {
    final selectedEvents = _getEventsForDay(_selectedDay!);
    if (selectedEvents.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No hay actividades programadas',
              style: GoogleFonts.inter(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: selectedEvents.length,
      itemBuilder: (context, index) {
        final activity = selectedEvents[index];
        return _buildActivityCard(activity);
      },
    );
  }

  Widget _buildActivityCard(Actividad activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacitySafe(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ActivityDetailView(actividad: activity),
            ),
          ),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time Strip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Text(
                            activity.horaInicio.substring(0, 5),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          Text(
                            '|',
                            style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 10),
                          ),
                          Text(
                            activity.horaFin.substring(0, 5),
                            style: GoogleFonts.inter(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  activity.puntoVenta,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getBgColorForStatus(activity.status),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  activity.status,
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: _getColorForStatus(activity.status),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity.codigos} • ${activity.ciudad}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Evidence Preview Section (On Demand)
                if (activity.status == 'En Curso' || activity.status == 'Finalizada')
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: _EvidencePreviewList(activityId: activity.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidencePreviewList extends StatefulWidget {
  final int activityId;
  const _EvidencePreviewList({required this.activityId});

  @override
  State<_EvidencePreviewList> createState() => _EvidencePreviewListState();
}

class _EvidencePreviewListState extends State<_EvidencePreviewList> {
  final ApiService _apiService = ApiService();
  late Future<List<Evidencia>> _evidenceFuture;

  @override
  void initState() {
    super.initState();
    _evidenceFuture = _apiService.getEvidenciasByActividadId(widget.activityId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Evidencia>>(
      future: _evidenceFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // Hide if no evidence or error
        }

        final evidences = snapshot.data!;
        return SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: evidences.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final evidence = evidences[index];
              return Container(
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                  image: DecorationImage(
                    image: NetworkImage(evidence.url),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) => const Icon(Icons.broken_image),
                  ),
                ),
                child: evidence.tipo != 'image' 
                    ? const Center(child: Icon(Icons.insert_drive_file, color: Colors.grey))
                    : null,
              );
            },
          ),
        );
      },
    );
  }
}
