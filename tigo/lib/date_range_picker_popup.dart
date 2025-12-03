import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tigo/app_colors.dart';
import 'package:intl/intl.dart'; // Import for DateFormat

class DateRangePickerPopup extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;

  const DateRangePickerPopup({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
  });

  @override
  State<DateRangePickerPopup> createState() => _DateRangePickerPopupState();
}

class _DateRangePickerPopupState extends State<DateRangePickerPopup> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
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
          children: [
            Text(
              'Seleccionar Rango de Fechas',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            CalendarDatePicker(
              initialDate: _startDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
              onDateChanged: (date) {
                setState(() {
                  if (_startDate == null || date.isBefore(_startDate!)) {
                    _startDate = date;
                    _endDate = null; // Reset end date if start date changes to before current start
                  } else if (_endDate == null || date.isAfter(_endDate!)) {
                    _endDate = date;
                  } else if (date.isAfter(_startDate!) && date.isBefore(_endDate!)) {
                    // If date is between current start and end, assume user wants to change start
                    _startDate = date;
                  } else {
                    _startDate = date;
                    _endDate = date;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _startDate != null ? DateFormat('dd/MM/yyyy').format(_startDate!) : 'Fecha Inicio',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
                const Text(' - ', style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                Text(
                  _endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'Fecha Fin',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cancel
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                  ),
                  child: Text('Cancelar', style: GoogleFonts.inter(fontSize: 16)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _startDate != null && _endDate != null
                      ? () {
                          Navigator.of(context).pop(DateTimeRange(start: _startDate!, end: _endDate!));
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Aplicar', style: GoogleFonts.inter(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
