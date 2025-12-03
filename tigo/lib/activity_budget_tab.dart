import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/actividad.dart';
import 'package:tigo/services/api_service.dart';

class ActivityBudgetTab extends StatefulWidget {
  final int actividadId;

  const ActivityBudgetTab({super.key, required this.actividadId});

  @override
  State<ActivityBudgetTab> createState() => _ActivityBudgetTabState();
}

class _ActivityBudgetTabState extends State<ActivityBudgetTab> {
  final ApiService _apiService = ApiService();
  Future<Presupuesto?>? _presupuestoFuture;

  @override
  void initState() {
    super.initState();
    _presupuestoFuture = _apiService.getPresupuestoByActividadId(widget.actividadId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Presupuesto?>(
      future: _presupuestoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error al cargar el presupuesto: ${snapshot.error}'));
        }

        final presupuesto = snapshot.data;

        if (presupuesto == null) {
          return const Center(child: Text('Esta actividad aún no tiene un presupuesto asignado.'));
        }

        final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: 'COP', decimalDigits: 0);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumen del Presupuesto',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const Divider(height: 24),
                  DataTable(
                    columns: const [
                      DataColumn(label: Text('Ítem')),
                      DataColumn(label: Text('Cantidad'), numeric: true),
                      DataColumn(label: Text('Costo Unitario'), numeric: true),
                      DataColumn(label: Text('Costo Total'), numeric: true),
                    ],
                    rows: presupuesto.items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.item)),
                        DataCell(Text(item.cantidad.toString())),
                        DataCell(Text(currencyFormatter.format(item.costoUnitario))),
                        DataCell(Text(currencyFormatter.format(item.costoTotal))),
                      ]);
                    }).toList(),
                  ),
                  const Divider(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Subtotal: ${currencyFormatter.format(presupuesto.subtotal)}',
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                        Text(
                          'IVA (${presupuesto.ivaPorcentaje}%): ${currencyFormatter.format(presupuesto.ivaValor)}',
                          style: GoogleFonts.inter(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Total General: ${currencyFormatter.format(presupuesto.totalCop)}',
                          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}