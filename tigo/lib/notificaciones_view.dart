import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/notificacion.dart';
import 'package:tigo/services/api_service.dart';
import 'package:intl/intl.dart';

class NotificacionesView extends StatefulWidget {
  const NotificacionesView({super.key});

  @override
  State<NotificacionesView> createState() => _NotificacionesViewState();
}

class _NotificacionesViewState extends State<NotificacionesView> {
  final ApiService _apiService = ApiService();
  late Future<List<Notificacion>> _notificacionesFuture;

  @override
  void initState() {
    super.initState();
    _loadNotificaciones();
  }

  void _loadNotificaciones() {
    setState(() {
      _notificacionesFuture = _apiService.getNotificaciones();
    });
  }

  Future<void> _markAsRead(int notificacionId) async {
    try {
      await _apiService.markNotificacionAsRead(notificacionId);
      _loadNotificaciones(); // Refresh the list
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar como leída: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Centro de Notificaciones',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded( // This will solve any potential overflow issue
            child: FutureBuilder<List<Notificacion>>(
              future: _notificacionesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error al cargar notificaciones: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }
                final notificaciones = snapshot.data ?? [];
                if (notificaciones.isEmpty) {
                  return const Center(child: Text('No tienes notificaciones nuevas.'));
                }
                return RefreshIndicator(
                  onRefresh: () async => _loadNotificaciones(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notificaciones.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final notificacion = notificaciones[index];
                      final bool isRead = notificacion.estado == 'leida';
                      final subject = notificacion.payload?['subject'] ?? 'Notificación';
                      final message = notificacion.payload?['context']?['motivo'] ?? 'Evento de actividad';
                      
                      return Card(
                        elevation: 2,
                        shadowColor: Colors.black.withAlpha(26),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isRead ? Colors.grey.shade200 : AppColors.primary.withAlpha(25),
                            child: Icon(
                              isRead ? Icons.mark_email_read_outlined : Icons.notifications_active,
                              color: isRead ? AppColors.textMuted : AppColors.primary,
                            ),
                          ),
                          title: Text(subject, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd/MM/yyyy HH:mm').format(notificacion.createdAt),
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                          trailing: isRead
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.check_circle, color: Colors.green),
                                  tooltip: 'Marcar como leída',
                                  onPressed: () => _markAsRead(notificacion.id),
                                ),
                          onTap: () {
                            // TODO: Navigate to the related activity using notificacion.actividad_id
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}