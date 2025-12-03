import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/actividad.dart';
import 'package:intl/intl.dart';

class ActivityDetailPopup extends StatelessWidget {
  final Actividad actividad;

  const ActivityDetailPopup({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.7, // Ancho del 70%
        constraints: const BoxConstraints(maxWidth: 800), // Máximo ancho
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacitySafe(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalle de Actividad',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Código(s):', actividad.codigos),
            _buildDetailRow('Agencia:', actividad.agencia),
            _buildDetailRow('Segmento:', actividad.segmento),
            _buildDetailRow('Clase Presupuesto:', actividad.clasePpto),
            _buildDetailRow('Canal:', actividad.canal),
            _buildDetailRow('Ciudad:', actividad.ciudad),
            _buildDetailRow('Punto de Venta:', actividad.puntoVenta),
            _buildDetailRow('Dirección:', actividad.direccion),
            _buildDetailRow('Fecha:', DateFormat('dd/MM/yyyy').format(actividad.fecha)),
            _buildDetailRow('Horario:', '${actividad.horaInicio} - ${actividad.horaFin}'),
            _buildDetailRow('Responsable Actividad:', actividad.responsableActividad),
            _buildDetailRow('Responsable Canal:', actividad.responsableCanal ?? 'N/A'),
            _buildDetailRow('Celular Responsable:', actividad.celularResponsable ?? 'N/A'),
            _buildDetailRow('Estado:', actividad.status),
            _buildDetailRow('Recursos Agencia:', actividad.recursosAgencia ?? 'N/A'),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text('Cerrar', style: GoogleFonts.inter(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
