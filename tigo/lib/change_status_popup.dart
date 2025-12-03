import 'package:collection/collection.dart'; // For firstWhereOrNull
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/actividad.dart';
import 'package:tigo/services/api_service.dart';

class ChangeStatusPopup extends StatefulWidget {
  final Actividad actividad;

  const ChangeStatusPopup({super.key, required this.actividad});

  @override
  State<ChangeStatusPopup> createState() => _ChangeStatusPopupState();
}

class _ChangeStatusPopupState extends State<ChangeStatusPopup> {
  final ApiService _apiService = ApiService();
  String? _selectedMainStatus;
  String? _selectedSubStatus;
  bool _isSubmitting = false;
  String? _errorMessage;
  final TextEditingController _motivoController = TextEditingController();
  String? _userRole;
  bool _isInitializing = true; // Flag to handle async initState

  late List<Map<String, String>> _availableTransitions;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _loadUserRole();
    _availableTransitions = _generateAvailableTransitions();
    
    if (_availableTransitions.isNotEmpty) {
      _selectedMainStatus = _availableTransitions.first['status'];
      _selectedSubStatus = _availableTransitions.first['subStatus'];
    } else {
      // Keep current status if no transitions are available
      _selectedMainStatus = widget.actividad.status;
      _selectedSubStatus = widget.actividad.subStatus;
    }

    setState(() {
      _isInitializing = false;
    });
  }

  Future<void> _loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    _userRole = prefs.getString('userRole');
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  List<Map<String, String>> _generateAvailableTransitions() {
    final List<Map<String, String>> transitions = [];
    final currentMainStatus = widget.actividad.status;
    final currentSubStatus = widget.actividad.subStatus;

    // Helper for roles (assuming role is loaded)
    bool isComercial = _userRole == 'Comercial';
    bool isProductor = _userRole == 'Productor';
    bool isCliente = _userRole == 'Cliente';

    debugPrint('ChangeStatusPopup Debug:');
    debugPrint('  Role: $_userRole');
    debugPrint('  Current Status: $currentMainStatus');
    debugPrint('  Current SubStatus: $currentSubStatus');
    debugPrint('  isCliente: $isCliente');

    // Phase 1: Creación y Validación Inicial
    if (currentMainStatus == 'Planificación') {
      if (currentSubStatus == 'Borrador') {
        if (isComercial) { // Comercial crea y envía a revisión
          transitions.add({'status': 'Planificación', 'subStatus': 'En Revisión', 'label': 'Enviar a Revisión Inicial (Cliente)'});
          transitions.add({'status': 'Finalizada', 'subStatus': 'Cancelado', 'label': 'Cancelar Actividad'});
        }
      } else if (currentSubStatus == 'En Revisión') {
        if (isCliente) { // Cliente valida inicialmente
          transitions.add({'status': 'Confirmada', 'subStatus': 'Programada', 'label': 'Aprobar Actividad'});
          transitions.add({'status': 'Planificación', 'subStatus': 'Rechazado', 'label': 'Rechazar Actividad'});
        }
      } else if (currentSubStatus == 'Rechazado') {
        if (isComercial) { // Comercial corrige y reenvía
          transitions.add({'status': 'Planificación', 'subStatus': 'En Revisión', 'label': 'Reenviar a Revisión Inicial'});
        }
      }
    }
    // Phase 2: Planificación y Presupuesto
    else if (currentMainStatus == 'Confirmada') {
      if (currentSubStatus == 'Programada') {
        if (isProductor) { // Productor inicia la ejecución
          transitions.add({'status': 'En Curso', 'subStatus': 'En Ejecución', 'label': 'Iniciar Ejecución'});
          transitions.add({'status': 'Finalizada', 'subStatus': 'Cancelado', 'label': 'Cancelar Actividad'});
        }
      }
    }
    // Phase 3: Ejecución y Evidencias
    else if (currentMainStatus == 'En Curso') {
      if (currentSubStatus == 'En Ejecución') {
        if (isProductor) { // Productor finaliza ejecución y carga evidencias
          transitions.add({'status': 'En Curso', 'subStatus': 'Cargando Evidencias', 'label': 'Finalizar Ejecución y Cargar Evidencias'});
          transitions.add({'status': 'Finalizada', 'subStatus': 'Cancelado', 'label': 'Cancelar Actividad'});
        }
      } else if (currentSubStatus == 'Cargando Evidencias') {
        if (isProductor) { // Productor envía a aprobación final
          transitions.add({'status': 'En Curso', 'subStatus': 'Aprobación Final', 'label': 'Enviar a Aprobación Final (Cliente)'});
        }
      } else if (currentSubStatus == 'Aprobación Final') {
        if (isCliente) { // Cliente da visto bueno final
          transitions.add({'status': 'Finalizada', 'subStatus': 'Completado', 'label': 'Dar Visto Bueno (Cierre Exitoso)'});
          transitions.add({'status': 'En Curso', 'subStatus': 'Cargando Evidencias', 'label': 'Rechazar Cierre (Requiere Observación)'});
        }
      }
    }
    // Finalizada is a terminal state, usually no transitions from here
    return transitions;
  }

  Future<void> _changeStatus() async {
    // Determine the selected transition map
    final selectedTransition = _availableTransitions.firstWhereOrNull(
      (element) => element['status'] == _selectedMainStatus && element['subStatus'] == _selectedSubStatus,
    );

    if (selectedTransition == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un estado de transición válido.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate if 'motivo' is required
    final bool isRejection = (selectedTransition['subStatus'] == 'Rechazado' && selectedTransition['status'] == 'Planificación') ||
                              (selectedTransition['status'] == 'En Curso' && selectedTransition['subStatus'] == 'Cargando Evidencias' && widget.actividad.subStatus == 'Aprobación Final');
    
    if (isRejection && _motivoController.text.isEmpty) {
      setState(() {
        _errorMessage = 'El motivo de rechazo es requerido.';
      });
      return;
    }

    if (_selectedMainStatus == null || _selectedSubStatus == null ||
        (_selectedMainStatus == widget.actividad.status && _selectedSubStatus == widget.actividad.subStatus)) {
      Navigator.of(context).pop(); // No change or no status selected
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _apiService.changeActividadStatus(
        widget.actividad.id,
        _selectedMainStatus!,
        _selectedSubStatus!,
        motivo: _motivoController.text.isNotEmpty ? _motivoController.text : null,
      );

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Estado de actividad actualizado con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true); // Indicar éxito y cerrar
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }
    
    // Determine if the reason field should be shown
    bool showMotivoField = (_selectedMainStatus == 'Planificación' && _selectedSubStatus == 'Rechazado') || 
                           (_selectedMainStatus == 'En Curso' && _selectedSubStatus == 'Cargando Evidencias' && widget.actividad.subStatus == 'Aprobación Final');

    // Filter available transitions based on current user role
    final List<Map<String, String>> filteredTransitions = _availableTransitions.where((transition) {
      return true;
    }).toList();

    // Set initial selected value if not already set or if current selection is no longer valid
    if (filteredTransitions.isNotEmpty && (_selectedMainStatus == null || _selectedSubStatus == null ||
        !filteredTransitions.any((t) => t['status'] == _selectedMainStatus && t['subStatus'] == _selectedSubStatus))) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedMainStatus = filteredTransitions.first['status'];
          _selectedSubStatus = filteredTransitions.first['subStatus'];
        });
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9, // More responsive width
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(24), // Slightly reduced padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacitySafe(0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
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
                  'Cambiar Estado',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAECF0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actividad ${widget.actividad.codigos}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Estado actual: ',
                        style: GoogleFonts.inter(fontSize: 14, color: AppColors.textMuted),
                      ),
                      Text(
                        '${widget.actividad.status}${widget.actividad.subStatus != null ? ' (${widget.actividad.subStatus})' : ''}',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<Map<String, String>>(
              initialValue: filteredTransitions.firstWhereOrNull(
                (element) => element['status'] == _selectedMainStatus && element['subStatus'] == _selectedSubStatus,
              ),
              decoration: const InputDecoration(
                labelText: 'Nuevo Estado',
                prefixIcon: Icon(Icons.swap_horiz_rounded, size: 20),
              ),
              items: filteredTransitions.map((transition) {
                return DropdownMenuItem<Map<String, String>>(
                  value: transition,
                  child: Text(
                    transition['label']!,
                    style: GoogleFonts.inter(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedMainStatus = value!['status'];
                  _selectedSubStatus = value['subStatus'];
                });
              },
              validator: (value) {
                if (value == null || value['status'] == null) {
                  return 'Por favor selecciona un estado';
                }
                return null;
              },
            ),
            if (showMotivoField)
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: TextFormField(
                  controller: _motivoController,
                  maxLines: 3,
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Motivo de Rechazo / Observación',
                    hintText: 'Describe la razón del cambio...',
                    alignLabelWithHint: true,
                  ),
                  validator: (value) {
                    if (showMotivoField && (value == null || value.isEmpty)) {
                      return 'Este campo es requerido.';
                    }
                    return null;
                  },
                ),
              ),
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECDCA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFB42318), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(color: const Color(0xFFB42318), fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text('Cancelar', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _changeStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Confirmar Cambio', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            ],
            ),
          ),
        ),
    );
  }
}