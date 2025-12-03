import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/actividad.dart';
import 'package:tigo/models/bitacora.dart';
import 'package:tigo/models/evidencia.dart';
import 'package:tigo/services/api_service.dart';
import 'package:tigo/utils/api_exception.dart';
import 'package:tigo/utils/web_utils.dart' if (dart.library.io) 'package:tigo/utils/stub_web_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:tigo/change_status_popup.dart';

class ActivityDetailView extends StatefulWidget {
  final Actividad actividad;

  const ActivityDetailView({super.key, required this.actividad});

  @override
  State<ActivityDetailView> createState() => _ActivityDetailViewState();
}

class _ActivityDetailViewState extends State<ActivityDetailView> {
  late Actividad _actividad;
  bool _hasChanged = false;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _actividad = widget.actividad;
    _loadUserRole();
  }

  Future<void> _refreshActivity() async {
    try {
      final updatedActivity = await ApiService().getActividadById(_actividad.id);
      if (updatedActivity != null) {
        setState(() {
          _actividad = updatedActivity;
          _hasChanged = true;
        });
      }
    } catch (e) {
      debugPrint('Error refreshing activity: $e');
    }
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole');
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_hasChanged);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Detalle: ${_actividad.codigos}', style: GoogleFonts.inter(color: AppColors.textDark)),
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: const IconThemeData(color: AppColors.textDark),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_hasChanged),
          ),
          actions: [
            if (_userRole == 'Comercial')
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Editar Actividad',
                onPressed: () => _showEditActivityDialog(context),
              ),
            IconButton(
              icon: const Icon(Icons.published_with_changes),
              tooltip: 'Gestionar Estado',
              onPressed: () async {
                final result = await showDialog(
                  context: context,
                  builder: (context) => ChangeStatusPopup(actividad: _actividad),
                );
                if (!mounted) return;
                if (result == true) {
                  await _refreshActivity();
                }
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Details Section
              _buildDetailsTab(_actividad),
              const SizedBox(height: 32),

              // Presupuesto y Evidencias Section (New Combined Section)
              // This will replace _BudgetAndEvidenceTab
              _buildPresupuestoEvidenciasSection(_actividad),
              const SizedBox(height: 32),

              // Bitácora Section
              // This will replace _LogTab
              _buildBitacoraSection(_actividad.id),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditActivityDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final valorTotalController = TextEditingController(text: _actividad.valorTotal.toString());
    final ApiService apiService = ApiService();

    // Add other controllers if needed, for now focusing on Valor Total as requested

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Actividad'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: valorTotalController,
                    decoration: const InputDecoration(labelText: 'Valor Total Actividad *'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  // Add more fields here if necessary
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    final double newValorTotal = double.parse(valorTotalController.text);
                    
                    // Create a copy of the activity with updated values
                    final updatedActivity = _actividad.copyWith(
                      valorTotal: newValorTotal,
                    );

                    await apiService.updateActividad(_actividad.id, updatedActivity);
                    
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Actividad actualizada con éxito'), backgroundColor: Colors.green),
                      );
                      await _refreshActivity();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
    
    // After dialog closes, if we want to refresh, we need to handle it.
    // I'll add the local state refactoring in the next step or include it here if possible.
    // For now, let's just add the dialog.
  }

  Widget _buildDetailsTab(Actividad actividad) {
    final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Estado Actual'),
          const SizedBox(height: 8),
          _buildStatusBadge(actividad.status, actividad.subStatus),
          const SizedBox(height: 24),
          _buildSectionHeader('Información General'),
          _buildDataCard(
            children: [
              _buildDataRow('Código(s)', actividad.codigos),
              _buildDataRow('Semana', actividad.semana),
              _buildDataRow('Agencia', actividad.agencia),
              _buildDataRow('Responsable', actividad.responsableActividad),
              _buildDataRow('Valor Total Actividad', currencyFormatter.format(actividad.valorTotal)),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Clasificación'),
          _buildDataCard(
            children: [
              _buildDataRow('Segmento', actividad.segmento),
              _buildDataRow('Clase Presupuesto', actividad.clasePpto),
              _buildDataRow('Canal', actividad.canal),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionHeader('Ubicación y Horario'),
          _buildDataCard(
            children: [
              _buildDataRow('Ciudad', actividad.ciudad),
              _buildDataRow('Punto de Venta', actividad.puntoVenta),
              _buildDataRow('Dirección', actividad.direccion),
              _buildDataRow('Fecha', DateFormat('dd/MM/yyyy').format(actividad.fecha)),
              _buildDataRow('Horario', '${actividad.horaInicio} - ${actividad.horaFin}'),
            ],
          ),
           const SizedBox(height: 24),
          _buildSectionHeader('Contacto y Recursos'),
           _buildDataCard(
            children: [
              _buildDataRow('Contacto PDV', actividad.responsableCanal),
              _buildDataRow('Celular Contacto', actividad.celularResponsable),
              _buildDataRow('Recursos Agencia', actividad.recursosAgencia, isMultiline: true),
            ]
           )
        ],
      ),
    );
  }

  // Presupuesto y Evidencias Section
  Widget _buildPresupuestoEvidenciasSection(Actividad actividad) {
    return _PresupuestoEvidenciasSection(actividadId: actividad.id);
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark),
    );
  }

  Widget _buildDataCard({required List<Widget> children}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFEAECF0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDataRow(String label, String? value, {bool isMultiline = false}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150.0,
            child: Text(
              label,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value ?? 'No disponible',
              style: GoogleFonts.inter(fontSize: 15, color: AppColors.textDark, height: isMultiline ? 1.5 : 1.0),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusBadge(String mainStatus, String? subStatus) {
    Color bgColor;
    Color textColor;
    String displayText = subStatus != null && subStatus != mainStatus && subStatus.isNotEmpty ? '$mainStatus: $subStatus' : mainStatus;

    switch (mainStatus) {
      case 'Planificación':
        bgColor = AppColors.statusRegistradaBg;
        textColor = AppColors.statusRegistradaText;
        break;
      case 'Confirmada':
        bgColor = AppColors.statusProgramadaBg;
        textColor = AppColors.statusProgramadaText;
        break;
      case 'En Curso':
        bgColor = AppColors.statusEjecucionBg;
        textColor = AppColors.statusEjecucionText;
        break;
      case 'Finalizada':
        if (subStatus == 'Completado') {
          bgColor = AppColors.statusCerradaBg;
          textColor = AppColors.statusCerradaText;
        } else if (subStatus == 'Cancelado' || subStatus == 'Rechazado') {
          bgColor = AppColors.statusRechazadaBg;
          textColor = AppColors.statusRechazadaText;
        } else {
          bgColor = AppColors.statusCerradaBg;
          textColor = AppColors.statusCerradaText;
        }
        break;
      default:
        bgColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: bgColor == Colors.white ? Colors.grey.shade200 : Colors.transparent),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }


  // Bitácora Section
  Widget _buildBitacoraSection(int actividadId) {
    final ApiService apiService = ApiService();
    return FutureBuilder<List<Bitacora>>(
      future: apiService.getBitacoraByActividadId(actividadId),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Bitácora'),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bitacora.length,
              itemBuilder: (context, index) {
                final registro = bitacora[index];
                String title = registro.accion ?? 'Actualización';
                if (registro.accion == 'Cambio de Estado') {
                  title = 'Cambio de Estado';
                }
                String subtitle = 'De: ${registro.desdeEstado ?? 'N/A'} \nA: ${registro.haciaEstado ?? 'N/A'}';

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.history, color: AppColors.primary),
                    title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (registro.accion == 'Cambio de Estado') Text(subtitle),
                        Text('Por: ${registro.usuario} el ${DateFormat('dd/MM/yyyy HH:mm').format(registro.fecha)}'),
                        if (registro.motivo != null && registro.motivo!.isNotEmpty)
                          Text('Motivo: ${registro.motivo}'),
                      ],
                    ),
                    isThreeLine: true,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
// Separate StatefulWidget for the Budget and Evidence Tab to manage its own state
class _PresupuestoEvidenciasSection extends StatefulWidget {
  final int actividadId;
  const _PresupuestoEvidenciasSection({required this.actividadId});

  @override
  State<_PresupuestoEvidenciasSection> createState() => _PresupuestoEvidenciasSectionState();
}

class _PresupuestoEvidenciasSectionState extends State<_PresupuestoEvidenciasSection> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  Future<Presupuesto?>? _presupuestoFuture;
  String? _userRole;
  
  // Use a map to hold futures for evidences of each item
  final Map<int, Future<List<Evidencia>>> _evidenceFutures = {};

  @override
  void initState() {
    super.initState();
    _refreshPresupuesto();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('userRole');
    });
  }

  void _refreshPresupuesto() {
    setState(() {
      _presupuestoFuture = _apiService.getPresupuestoByActividadId(widget.actividadId);
    });
  }

  void _refreshEvidenceFor(int presupuestoItemId) {
    setState(() {
      _evidenceFutures[presupuestoItemId] = _apiService.getEvidenciasByPresupuestoItemId(presupuestoItemId);
    });
  }

  Future<void> _pickAndUploadImage(int presupuestoItemId) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image == null) return;

    setState(() { _isUploading = true; });

    try {
      final bytes = await image.readAsBytes();
      await _apiService.uploadEvidencia(presupuestoItemId, bytes, image.name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Evidencia subida con éxito'), backgroundColor: Colors.green),
      );
      _refreshEvidenceFor(presupuestoItemId);
    } on ApiException catch (e) {
      if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al subir evidencia: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch(e) {
       if (!mounted) return;
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
      );
    }
    finally {
      if (mounted) {
        setState(() { _isUploading = false; });
      }
    }
  }

  String _getPresupuestoItemValidationStatus(List<Evidencia> evidences) {
    if (evidences.isEmpty) {
      return 'Sin Evidencia';
    }

    bool hasRejected = false;
    bool hasPending = false;

    for (var evidence in evidences) {
      if (evidence.status == 'rechazado') {
        hasRejected = true;
        break;
      }
      if (evidence.status == 'pendiente') {
        hasPending = true;
      }
    }

    if (hasRejected) {
      return 'Rechazado';
    } else if (hasPending) {
      return 'Pendiente';
    } else {
      return 'Aprobado';
    }
  }

  Future<void> _showEvidenceValidationDialog(PresupuestoItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('userRole');

    if (!mounted) return;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              title: Text('Validar Evidencias para ${item.item}'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildItemEvidenceSection(item.id, showValidationActions: role == 'Cliente'),
                      const SizedBox(height: 16),
                      if (role == 'Productor')
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _pickAndUploadImage(item.id);
                              // Refresh the dialog to show the new evidence
                              dialogSetState(() {});
                            },
                            icon: const Icon(Icons.add_photo_alternate, size: 20),
                            label: Text('Añadir Evidencia', style: GoogleFonts.inter(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cerrar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _updateEvidenceStatus(Evidencia evidencia, String newStatus) async {
    String? motivoRechazo;

    if (newStatus == 'rechazado') {
      motivoRechazo = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          final TextEditingController controller = TextEditingController();
          return AlertDialog(
            title: const Text('Motivo de Rechazo'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'Explica por qué se rechaza la evidencia'),
            ),
            actions: [
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.of(context).pop()),
              TextButton(child: const Text('Confirmar Rechazo'), onPressed: () => Navigator.of(context).pop(controller.text)),
            ],
          );
        },
      );
      if (motivoRechazo == null || motivoRechazo.isEmpty) return; // User cancelled or didn't provide a reason
    }
    
    try {
      await _apiService.updateEvidenciaStatus(evidencia.id, newStatus, motivoRechazo);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado de la evidencia actualizado a "$newStatus"'), backgroundColor: Colors.green),
      );
      _refreshEvidenceFor(evidencia.presupuestoItemId);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e'), backgroundColor: Colors.red),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    // Scaffold removed, directly returning the content
    return Stack(
      children: [
        FutureBuilder<Presupuesto?>(
          future: _presupuestoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _buildErrorWidget('Error al cargar el presupuesto: ${snapshot.error}');
            }
            final presupuesto = snapshot.data;
            if (presupuesto == null) {
              return _buildErrorWidget('Esta actividad aún no tiene un presupuesto asignado.');
            }

            final currencyFormatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Financial Summary Card
                  Card(
                     elevation: 0,
                     shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Subtotal: ${currencyFormatter.format(presupuesto.subtotal)}', style: GoogleFonts.inter(fontSize: 16)),
                            Text('IVA (${presupuesto.ivaPorcentaje}%): ${currencyFormatter.format(presupuesto.ivaValor)}', style: GoogleFonts.inter(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text('Total General: ${currencyFormatter.format(presupuesto.totalCop)}', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            if (presupuesto.archivoOc != null)
                              ElevatedButton.icon(
                                onPressed: () {
                                   // Construct URL
                                   // TODO: Use a proper config for base URL
                                   final url = 'http://localhost:3000${presupuesto.archivoOc}'; 
                                   _showOCPreview(context, url);
                                },
                                icon: const Icon(Icons.visibility, size: 18),
                                label: const Text('Ver Orden de Compra'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            if (_userRole == 'Cliente' && presupuesto.archivoOc == null)
                              ElevatedButton.icon(
                                onPressed: () => _pickAndUploadOC(presupuesto.id),
                                icon: const Icon(Icons.upload_file, size: 18),
                                label: const Text('Cargar Orden de Compra (OC)'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                             if (_userRole == 'Cliente' && presupuesto.archivoOc != null)
                              TextButton.icon(
                                onPressed: () => _pickAndUploadOC(presupuesto.id),
                                icon: const Icon(Icons.edit, size: 16),
                                label: const Text('Actualizar OC'),
                              ),
                          ],
                        ),
                      ),
                    )
                  ),
                  const SizedBox(height: 24),
                  // Items List
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: presupuesto.items.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 24),
                    itemBuilder: (context, index) {
                      final item = presupuesto.items[index];
                      final evidencesFuture = _evidenceFutures.putIfAbsent(item.id, () => _apiService.getEvidenciasByPresupuestoItemId(item.id));

                      return FutureBuilder<List<Evidencia>>(
                        future: evidencesFuture,
                        builder: (context, evidenceSnapshot) {
                          String validationStatus = 'Cargando...';
                          Color statusColor = Colors.grey;

                          if (evidenceSnapshot.connectionState == ConnectionState.done && !evidenceSnapshot.hasError) {
                            validationStatus = _getPresupuestoItemValidationStatus(evidenceSnapshot.data ?? []);
                            switch (validationStatus) {
                              case 'Aprobado':
                                statusColor = Colors.green;
                                break;
                              case 'Rechazado':
                                statusColor = Colors.red;
                                break;
                              case 'Pendiente':
                                statusColor = Colors.orange;
                                break;
                              default:
                                statusColor = Colors.grey;
                            }
                          }

                          return Card(
                            elevation: 2,
                            shadowColor: Colors.black.withAlpha(13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(child: Text(item.item, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 16, color: AppColors.textDark))),
                                      Row(
                                        children: [
                                          Text(currencyFormatter.format(item.costoTotal), style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                                          if (_userRole == 'Comercial') ...[
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.edit, size: 20, color: AppColors.primary),
                                              onPressed: () => _showEditBudgetDialog(context, item),
                                              tooltip: 'Editar Ítem',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                              onPressed: () => _confirmDeleteBudgetItem(context, item),
                                              tooltip: 'Eliminar Ítem',
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (item.comentario != null && item.comentario!.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text('Obs: ${item.comentario}', style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                                    ),
                                  const Divider(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Estado Validación', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor.withAlpha(25),
                                              borderRadius: BorderRadius.circular(9999),
                                            ),
                                            child: Text(
                                              validationStatus,
                                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: statusColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                      ElevatedButton(
                                        onPressed: () => _showEvidenceValidationDialog(item),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: const Text('Ver / Validar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_userRole == 'Comercial')
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddBudgetDialog(context, presupuesto.id),
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text('Agregar Ítem'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (_isUploading)
          Container(
            color: Colors.black.withAlpha(128),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white)),
                  SizedBox(height: 16),
                  Text('Subiendo evidencia...', style: TextStyle(color: Colors.white, fontSize: 16)),
                ],
              ),
            ),
          ),
      ],
    );
  }



  Future<void> _showEditBudgetDialog(BuildContext context, PresupuestoItem item) async {
    final formKey = GlobalKey<FormState>();
    final itemController = TextEditingController(text: item.item);
    final cantidadController = TextEditingController(text: item.cantidad.toString());
    final costoController = TextEditingController(text: item.costoUnitario.toString());
    final comentarioController = TextEditingController(text: item.comentario);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Ítem del Presupuesto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: itemController,
                    decoration: const InputDecoration(labelText: 'Ítem *'),
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: cantidadController,
                    decoration: const InputDecoration(labelText: 'Cantidad *'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: costoController,
                    decoration: const InputDecoration(labelText: 'Costo Unitario *'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: comentarioController,
                    decoration: const InputDecoration(labelText: 'Comentario'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Actualizar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final cantidad = int.parse(cantidadController.text);
                  final costo = double.parse(costoController.text);
                  final subtotal = cantidad * costo;
                  
                  final itemData = {
                    'item': itemController.text,
                    'cantidad': cantidad,
                    'costo_unitario_cop': costo,
                    'subtotal_cop': subtotal,
                    'impuesto_cop': 0, 
                    'comentario': comentarioController.text,
                  };

                  try {
                    await _apiService.updatePresupuestoItem(item.id, itemData);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ítem actualizado con éxito'), backgroundColor: Colors.green),
                      );
                      _refreshPresupuesto();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDeleteBudgetItem(BuildContext context, PresupuestoItem item) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Eliminación'),
          content: Text('¿Estás seguro de que deseas eliminar el ítem "${item.item}"? Esta acción no se puede deshacer.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await _apiService.deletePresupuestoItem(item.id);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ítem eliminado con éxito'), backgroundColor: Colors.green),
                    );
                    _refreshPresupuesto();
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddBudgetDialog(BuildContext context, int presupuestoId) async {
    final formKey = GlobalKey<FormState>();
    final itemController = TextEditingController();
    final cantidadController = TextEditingController();
    final costoController = TextEditingController();
    final comentarioController = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Agregar Ítem al Presupuesto'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: itemController,
                    decoration: const InputDecoration(labelText: 'Ítem *'),
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: cantidadController,
                    decoration: const InputDecoration(labelText: 'Cantidad *'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: costoController,
                    decoration: const InputDecoration(labelText: 'Costo Unitario *'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
                  ),
                  TextFormField(
                    controller: comentarioController,
                    decoration: const InputDecoration(labelText: 'Comentario'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Guardar'),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final cantidad = int.parse(cantidadController.text);
                  final costo = double.parse(costoController.text);
                  final subtotal = cantidad * costo;
                  
                  final itemData = {
                    'item': itemController.text,
                    'cantidad': cantidad,
                    'costo_unitario_cop': costo,
                    'subtotal_cop': subtotal,
                    'impuesto_cop': 0, 
                    'comentario': comentarioController.text,
                  };

                  try {
                    await _apiService.addPresupuestoItem(presupuestoId, itemData);
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ítem agregado con éxito'), backgroundColor: Colors.green),
                      );
                      _refreshPresupuesto();
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          message,
          style: GoogleFonts.inter(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildItemEvidenceSection(int presupuestoItemId, {bool showValidationActions = false}) {
    return FutureBuilder<List<Evidencia>>(
      future: _evidenceFutures.putIfAbsent(presupuestoItemId, () => _apiService.getEvidenciasByPresupuestoItemId(presupuestoItemId)),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red));
        }
        final evidences = snapshot.data ?? [];
        if (evidences.isEmpty) {
          return Center(child: Text('No hay evidencias para este ítem.', style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: AppColors.textMuted)));
        }

        return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate item width for 3 columns with 8px spacing
          // Total spacing = (3 - 1) * 8 = 16. But Wrap spacing applies between items.
          // If we want 3 items to fit exactly: 3 * w + 2 * 8 <= maxWidth
          // w = (maxWidth - 16) / 3
          final double itemWidth = (constraints.maxWidth - 16) / 3;
          
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: evidences.map((evidencia) {
              return SizedBox(
                width: itemWidth,
                height: itemWidth,
                child: Card(
                  elevation: 1,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      InkWell(
                        onTap: () { if (kIsWeb) downloadFileFromUrl(evidencia.url, evidencia.nombre); },
                        child: GridTile(
                          footer: evidencia.comentario != null ? GridTileBar(
                            backgroundColor: Colors.black54,
                            title: Text(evidencia.comentario!, style: GoogleFonts.inter(fontSize: 10)),
                          ) : null,
                          child: Image.network(
                            evidencia.url,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) => progress == null ? child : const Center(child: CircularProgressIndicator()),
                            errorBuilder: (context, error, stack) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                          ),
                        ),
                      ),
                      if (showValidationActions && evidencia.status == 'pendiente')
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Row(
                            children: [
                              IconButton(icon: const Icon(Icons.check_circle, color: Colors.green), onPressed: () => _updateEvidenceStatus(evidencia, 'aprobado')),
                              IconButton(icon: const Icon(Icons.cancel, color: Colors.red), onPressed: () => _updateEvidenceStatus(evidencia, 'rechazado')),
                            ],
                          ),
                        ),
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(153),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            evidencia.status.toUpperCase(),
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
      },
    ); // Closes LayoutBuilder
        }, // Closes FutureBuilder builder
      ); // Closes FutureBuilder
  } // Closes method

  Future<void> _showOCPreview(BuildContext context, String url) async {
    final extension = url.split('.').last.toLowerCase();
    final isImage = ['jpg', 'jpeg', 'png', 'webp'].contains(extension);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Orden de Compra', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Content
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: isImage
                            ? Image.network(
                                url,
                                fit: BoxFit.contain,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(child: CircularProgressIndicator());
                                },
                                errorBuilder: (context, error, stackTrace) => const Center(child: Text('Error al cargar la imagen')),
                              )
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.picture_as_pdf, size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text('Este documento es un PDF.', style: GoogleFonts.inter(fontSize: 16)),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      // Open in new tab
                                      // We need url_launcher or just use web_utils if available
                                      // Assuming downloadFileFromUrl opens in new tab/downloads
                                      downloadFileFromUrl(url, 'Orden_Compra.pdf');
                                    },
                                    icon: const Icon(Icons.open_in_new),
                                    label: const Text('Abrir / Descargar PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadOC(int presupuestoId) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'png', 'jpeg'],
        withData: true, // Important for web
      );

      if (result != null) {
        setState(() => _isUploading = true);
        
        Uint8List? fileBytes = result.files.first.bytes;
        String fileName = result.files.first.name;

        if (fileBytes == null) {
           throw Exception('No se pudo leer el archivo');
        }

        await _apiService.uploadOC(presupuestoId, fileBytes, fileName);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Orden de Compra cargada exitosamente'), backgroundColor: Colors.green),
          );
          _refreshPresupuesto();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir OC: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

}

