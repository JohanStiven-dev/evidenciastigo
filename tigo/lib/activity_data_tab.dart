import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/actividad.dart';
import 'package:intl/intl.dart';

class ActivityDataTab extends StatelessWidget {
  final Actividad actividad;

  const ActivityDataTab({super.key, required this.actividad});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDataCard(
            context,
            title: 'Información General',
            children: [
              _buildReadOnlyField('Código(s)', actividad.codigos),
              _buildReadOnlyField('Semana', actividad.semana),
              _buildReadOnlyField('Agencia', actividad.agencia),
              _buildReadOnlyField('Responsable Actividad', actividad.responsableActividad),
            ],
          ),
          const SizedBox(height: 20),
          _buildDataCard(
            context,
            title: 'Clasificación',
            children: [
              _buildReadOnlyField('Segmento', actividad.segmento),
              _buildReadOnlyField('Clase Presupuesto', actividad.clasePpto),
              _buildReadOnlyField('Canal', actividad.canal),
            ],
          ),
          const SizedBox(height: 20),
          _buildDataCard(
            context,
            title: 'Ubicación y Horario',
            children: [
              _buildReadOnlyField('Ciudad', actividad.ciudad),
              _buildReadOnlyField('Punto de Venta (PDV)', actividad.puntoVenta),
              _buildReadOnlyField('Dirección', actividad.direccion),
              _buildReadOnlyField('Fecha', DateFormat('dd/MM/yyyy').format(actividad.fecha)),
              _buildReadOnlyField('Horario', '${actividad.horaInicio} - ${actividad.horaFin}'),
            ],
          ),
           const SizedBox(height: 20),
          _buildDataCard(
            context,
            title: 'Contacto y Recursos',
            children: [
              _buildReadOnlyField('Responsable del Canal', actividad.responsableCanal),
              _buildReadOnlyField('Celular Responsable', actividad.celularResponsable),
              _buildReadOnlyField('Recursos Agencia', actividad.recursosAgencia, isMultiline: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(BuildContext context, {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String? value, {bool isMultiline = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'No disponible',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.textDark,
              height: isMultiline ? 1.5 : 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
