import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/bitacora.dart';
import 'package:tigo/services/api_service.dart';

class ActivityLogTab extends StatefulWidget {
  final int actividadId;

  const ActivityLogTab({super.key, required this.actividadId});

  @override
  State<ActivityLogTab> createState() => _ActivityLogTabState();
}

class _ActivityLogTabState extends State<ActivityLogTab> {
  final ApiService _apiService = ApiService();
  Future<List<Bitacora>>? _bitacoraFuture;

  @override
  void initState() {
    super.initState();
    _bitacoraFuture = _apiService.getBitacoraByActividadId(widget.actividadId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Bitacora>>(
      future: _bitacoraFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar la bitácora: ${snapshot.error}'));
        }

        final bitacora = snapshot.data;

        if (bitacora == null || bitacora.isEmpty) {
          return const Center(child: Text('No hay registros en la bitácora para esta actividad.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: bitacora.length,
          itemBuilder: (context, index) {
            final registro = bitacora[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: const Icon(Icons.history, color: AppColors.primary),
                title: Text(
                  registro.accion == 'Cambio de Estado' 
                    ? '${registro.desdeEstado ?? ''} → ${registro.haciaEstado ?? ''}'
                    : registro.accion ?? 'Actualización',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Por: ${registro.usuario} el ${DateFormat('dd/MM/yyyy HH:mm').format(registro.fecha)}\nMotivo: ${registro.motivo ?? 'N/A'}',
                  style: GoogleFonts.inter(color: AppColors.textMuted),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }
}
