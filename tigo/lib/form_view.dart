import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/services/api_service.dart';
import 'package:tigo/models/catalogo.dart';
import 'package:tigo/models/actividad.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart'; // Importar para DateFormat
import 'package:tigo/utils/api_exception.dart'; // Import for ApiException

class FormView extends StatefulWidget {
  final Actividad? actividadToEdit; // Actividad opcional para edición

  const FormView({super.key, this.actividadToEdit});

  @override
  State<FormView> createState() => _FormViewState();
}

class _FormViewState extends State<FormView> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  String? _selectedAgencia;
  String? _selectedSegmento;
  String? _selectedClasePpto;
  String? _selectedCanal;
  String? _selectedCiudad;

  final TextEditingController _codigosController = TextEditingController();
  final TextEditingController _responsableActController = TextEditingController();
  final TextEditingController _pdvController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _fechaController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFinController = TextEditingController();
  final TextEditingController _responsableCanalController = TextEditingController();
  final TextEditingController _celularController = TextEditingController();
  final TextEditingController _recursosController = TextEditingController();
  final TextEditingController _valorTotalController = TextEditingController(); // New controller for valorTotal
  
  TimeOfDay? _selectedStartTime;
  TimeOfDay? _selectedEndTime;

  List<Catalogo> _segmentos = [];
  List<Catalogo> _clasePptos = [];
  List<Catalogo> _canales = [];
  List<Catalogo> _ciudades = [];

  bool _isLoadingCatalogs = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  String _calculatedWeek = '';

  // Function to calculate ISO week number and year
  String _calculateIsoWeekAndYear(DateTime date) {
    // Adjust to Monday as the first day of the week
    DateTime monday = date.subtract(Duration(days: date.weekday - 1));

    // January 4th is always in week 1 of its year
    int year = monday.year;
    DateTime jan4 = DateTime(year, 1, 4);
    DateTime firstMonday = jan4.subtract(Duration(days: jan4.weekday - 1));

    // Calculate the week number
    int week = ((monday.difference(firstMonday).inDays / 7) + 1).floor();

    // Handle cases where the week belongs to the previous or next year
    if (week == 0) {
      return _calculateIsoWeekAndYear(DateTime(year - 1, 12, 28));
    } else if (week == 53 && DateTime(year, 12, 31).weekday < DateTime.thursday) {
      return _calculateIsoWeekAndYear(DateTime(year + 1, 1, 4));
    }

    return 'ISO $week ($year)';
  }

  // Helper to convert 12h time (e.g., "5:00 PM") to 24h time (e.g., "17:00")
  String _convertTo24Hour(String time12h) {
    try {
      // Normalize spaces (replace non-breaking spaces \u00A0 and \u202F with standard space)
      time12h = time12h.replaceAll(RegExp(r'[\u00A0\u202F]'), ' ').trim();
      final format12 = DateFormat.jm(); // "5:00 PM"
      final date = format12.parse(time12h);
      final format24 = DateFormat('HH:mm'); // "17:00"
      return format24.format(date);
    } catch (e) {
      debugPrint('Error converting time: $e');
      return time12h; // Return original if parsing fails (fallback)
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchCatalogsAndSetupForm();
    _loadUserData();
    if (widget.actividadToEdit != null) {
      _valorTotalController.text = widget.actividadToEdit!.valorTotal.toString();
    }
  }

  @override
  void dispose() {
    _codigosController.dispose();
    _responsableActController.dispose();
    _pdvController.dispose();
    _direccionController.dispose();
    _fechaController.dispose();
    _horaInicioController.dispose();
    _horaFinController.dispose();
    _responsableCanalController.dispose();
    _celularController.dispose();
    _recursosController.dispose();
    _valorTotalController.dispose(); // Dispose new controller
    super.dispose();
  }

  Future<void> _fetchCatalogsAndSetupForm() async {
    setState(() {
      _isLoadingCatalogs = true;
      _errorMessage = null;
    });

    try {
      // Fetch all catalogs in parallel
      final responses = await Future.wait([
        _apiService.getCatalogos('segmento'),
        _apiService.getCatalogos('clase_ppto'),
        _apiService.getCatalogos('canal'),
        _apiService.getCatalogos('ciudad'),
      ]);

      if (!mounted) return;

      setState(() {
        _segmentos = responses[0];
        _clasePptos = responses[1];
        _canales = responses[2];
        _ciudades = responses[3];

        // If editing, ensure the activity's current values exist in the dropdown lists
        if (widget.actividadToEdit != null) {
          _ensureValueInCatalog(_segmentos, widget.actividadToEdit!.segmento, 'segmento');
          _ensureValueInCatalog(_clasePptos, widget.actividadToEdit!.clasePpto, 'clase_ppto');
          _ensureValueInCatalog(_canales, widget.actividadToEdit!.canal, 'canal');
          _ensureValueInCatalog(_ciudades, widget.actividadToEdit!.ciudad, 'ciudad');

          // Set initial values for the form controllers and dropdowns
          _codigosController.text = widget.actividadToEdit!.codigos;
          _responsableActController.text = widget.actividadToEdit!.responsableActividad;
          _pdvController.text = widget.actividadToEdit!.puntoVenta;
          _direccionController.text = widget.actividadToEdit!.direccion;
          _fechaController.text = DateFormat('yyyy-MM-dd').format(widget.actividadToEdit!.fecha);
          _horaInicioController.text = widget.actividadToEdit!.horaInicio;
          _horaFinController.text = widget.actividadToEdit!.horaFin;
          _responsableCanalController.text = widget.actividadToEdit!.responsableCanal ?? '';
          _celularController.text = widget.actividadToEdit!.celularResponsable ?? '';
          _recursosController.text = widget.actividadToEdit!.recursosAgencia ?? '';
          
          _selectedAgencia = 'Bull marketing';
          _selectedSegmento = widget.actividadToEdit!.segmento;
          _selectedClasePpto = widget.actividadToEdit!.clasePpto;
          _selectedCanal = widget.actividadToEdit!.canal;
          _selectedCiudad = widget.actividadToEdit!.ciudad;
          _selectedCiudad = widget.actividadToEdit!.ciudad;
          _calculatedWeek = _calculateIsoWeekAndYear(widget.actividadToEdit!.fecha);
          
          // Parse initial times for validation logic
          try {
             // Assuming backend sends HH:mm:ss or HH:mm
             final startParts = widget.actividadToEdit!.horaInicio.split(':');
             final endParts = widget.actividadToEdit!.horaFin.split(':');
             if (startParts.length >= 2) {
               _selectedStartTime = TimeOfDay(hour: int.parse(startParts[0]), minute: int.parse(startParts[1]));
             }
             if (endParts.length >= 2) {
               _selectedEndTime = TimeOfDay(hour: int.parse(endParts[0]), minute: int.parse(endParts[1]));
             }
          } catch (e) {
            debugPrint('Error parsing initial times: $e');
          }
        } else {
          _selectedAgencia = 'Bull marketing';
          _calculatedWeek = _calculateIsoWeekAndYear(DateTime.now());
        }

        _isLoadingCatalogs = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar catálogos: ${e.message}';
        _isLoadingCatalogs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error inesperado al cargar catálogos: $e';
        _isLoadingCatalogs = false;
      });
    }
  }

  void _ensureValueInCatalog(List<Catalogo> catalog, String value, String tipo) {
    if (!catalog.any((c) => c.valor == value)) {
      catalog.add(Catalogo(id: value, valor: value, tipo: tipo));
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('userName') ?? 'Usuario Desconocido';
    final userRole = prefs.getString('userRole') ?? 'Rol Desconocido';
    _responsableActController.text = '$userName ($userRole)';
  }



  Future<void> _submitForm({bool isDraft = false}) async { // Eliminar BuildContext
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); // Assuming userId is stored on login

      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Error: ID de usuario no encontrado. Por favor, inicia sesión de nuevo.';
          _isSubmitting = false;
        });
        return;
      }

      final actividadToSave = Actividad(
        id: widget.actividadToEdit?.id ?? 0, // Usar ID existente si es edición, sino 0
        comercialId: userId,
        agencia: _selectedAgencia!,
        codigos: _codigosController.text,
        semana: _calculatedWeek, // Usar la semana calculada dinámicamente
        responsableActividad: _responsableActController.text,
        segmento: _selectedSegmento!,
        clasePpto: _selectedClasePpto!,
        canal: _selectedCanal!,
        ciudad: _selectedCiudad!,
        puntoVenta: _pdvController.text,
        direccion: _direccionController.text,
        fecha: DateTime.parse(_fechaController.text),
        // Use the stored TimeOfDay objects to ensure 24h format (HH:mm)
        horaInicio: _selectedStartTime != null 
            ? '${_selectedStartTime!.hour.toString().padLeft(2, '0')}:${_selectedStartTime!.minute.toString().padLeft(2, '0')}' 
            : _convertTo24Hour(_horaInicioController.text), // Fallback
        horaFin: _selectedEndTime != null 
            ? '${_selectedEndTime!.hour.toString().padLeft(2, '0')}:${_selectedEndTime!.minute.toString().padLeft(2, '0')}' 
            : _convertTo24Hour(_horaFinController.text), // Fallback
        status: widget.actividadToEdit?.status ?? 'Planificación', // Default for new, preserve for edit
        subStatus: widget.actividadToEdit?.subStatus ?? 'Borrador', // Default for new, preserve for edit
        valorTotal: double.parse(_valorTotalController.text), // New field
        responsableCanal: _responsableCanalController.text,
        celularResponsable: _celularController.text,
        recursosAgencia: _recursosController.text,
        createdAt: widget.actividadToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        Actividad? resultActividad;
        if (widget.actividadToEdit == null) {
          resultActividad = await _apiService.createActividad(actividadToSave);
        } else {
          resultActividad = await _apiService.updateActividad(actividadToSave.id, actividadToSave);
        }

        if (!mounted) return;

        setState(() {
          _isSubmitting = false;
        });

        if (resultActividad != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Actividad ${widget.actividadToEdit == null ? 'Registrada' : 'Actualizada'} con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Cerrar popup y indicar éxito
        }
      } on ApiException catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.message;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Ocurrió un error inesperado: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error inesperado al ${widget.actividadToEdit == null ? 'registrar' : 'actualizar'} actividad.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }





  @override
  Widget build(BuildContext context) {
    if (_isLoadingCatalogs) {
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
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Crear Actividad: Planificación Asistida',
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
                        color: AppColors.primary.withOpacitySafe(0.05),
                      ),
                      child: Text(
                          '¡Completa todos los campos! La Semana se autocalculará.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildFormRow(
                      context,
                      children: [
                        _buildTextField(
                          'Códigos (Máx 5)',
                          _codigosController,
                          hintText: 'CÓD1, CÓD2, ...',
                          maxLength: 150,
                        ),
                        _buildTextField(
                          'Semana (Autocalculada)',
                          TextEditingController(text: _calculatedWeek),
                          enabled: false,
                          backgroundColor: Colors.grey.shade100,
                        ),
                      ],
                    ),
                    _buildFormRow(
                      context,
                      children: [
                        _buildDropdownField(
                          'Segmento *',
                          _segmentos.map((c) => c.valor).toList(),
                          _selectedSegmento,
                          (value) => setState(() => _selectedSegmento = value),
                          initialValue: _selectedSegmento,
                        ),
                        _buildDropdownField(
                          'Clase Presupuesto *',
                          _clasePptos.map((c) => c.valor).toList(),
                          _selectedClasePpto,
                          (value) => setState(() => _selectedClasePpto = value),
                          initialValue: _selectedClasePpto,
                        ),
                        _buildDropdownField(
                          'Canal *',
                          _canales.map((c) => c.valor).toList(),
                          _selectedCanal,
                          (value) => setState(() => _selectedCanal = value),
                          initialValue: _selectedCanal,
                        ),
                        _buildTextField(
                          'Responsable Actividad *',
                          _responsableActController,
                        ),
                      ],
                    ),
                    _buildFormRow(
                      context,
                      children: [
                        _buildDropdownField(
                          'Ciudad *',
                          _ciudades.map((c) => c.valor).toList(),
                          _selectedCiudad,
                          (value) => setState(() => _selectedCiudad = value),
                          initialValue: _selectedCiudad,
                        ),
                        _buildTextField(
                          'Punto de Venta (PDV) *',
                          _pdvController,
                          hintText: 'Ej: Supermercado Centro',
                          maxLength: 150,
                        ),
                        _buildTextField(
                          'Dirección *',
                          _direccionController,
                          hintText: 'Carrera 10 # 25-15',
                          maxLength: 150,
                        ),
                      ],
                    ),
                    _buildFormRow(
                      context,
                      children: [
                        _buildDateField(
                          'Fecha *',
                          DateTime.now(), // Placeholder
                          _fechaController,
                        ),
                        _buildTimeField(
                          'Hora Inicio *',
                          TimeOfDay.now(), // Placeholder
                          _horaInicioController,
                        ),
                        _buildTimeField(
                          'Hora Fin * (Fin > Inicio)',
                          TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 2))), // Placeholder
                          _horaFinController,
                        ),
                      ],
                    ),
                    _buildFormRow(
                      context,
                      children: [
                        _buildTextField(
                          'Responsable del Canal *',
                          _responsableCanalController,
                          hintText: 'Nombre contacto PDV',
                          maxLength: 150,
                        ),
                        _buildTextField(
                          'Celular Responsable * (10 dígitos)',
                          _celularController,
                          hintText: '300 123 4567',
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un número de celular';
                            }
                            if (value.length != 10) {
                              return 'El celular debe tener 10 dígitos';
                            }
                            return null;
                          },
                        ),
                        _buildTextField(
                          'Valor Total de Actividad *',
                          _valorTotalController,
                          hintText: 'Ej: 1500000.00',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa un valor total';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Debe ser un número válido';
                            }
                            if (double.parse(value) <= 0) {
                              return 'El valor debe ser mayor a 0';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Recursos Agencia (LLM Output)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recursos Agencia (Descripción Detallada)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _recursosController,
                          maxLines: 6,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            hintText: 'Escribe aquí los recursos...', 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.all(12),
                            counterText: "",
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                          validator: (value) {
                            if (value != null && value.length > 1000) {
                              return 'Máximo 1000 caracteres';
                            }
                            return null;
                          },
                        ),

                      ],
                    ),
                    const SizedBox(height: 24),
                    // Form Buttons
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Builder( // Envuelve con Builder
                        builder: (BuildContext builderContext) { // Usa builderContext
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: _isSubmitting ? null : () => _submitForm(isDraft: true),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: const Text('Guardar Borrador'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isSubmitting ? null : () => _submitForm(isDraft: false), // Ya no pasa builderContext
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                                    : Text('Registrar (Cambia a \'Registrada\')', style: GoogleFonts.inter(fontSize: 14)),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormRow(BuildContext context, {required List<Widget> children}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: constraints.maxWidth > 600 ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            // Adjusted aspect ratio to prevent overflow. 
            // Mobile: 2.5 (was 5) allows more height. Desktop: 2.5 (was 3) allows slightly more height.
            childAspectRatio: constraints.maxWidth > 600 ? 2.5 : 2.5, 
            children: children.map((child) => Align(alignment: Alignment.topLeft, child: child)).toList(),
          );
        },
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {String? hintText, bool enabled = true, Color? backgroundColor, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, int? maxLength}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: backgroundColor != null,
            fillColor: backgroundColor,
            counterText: "", // Oculta el contador de caracteres por defecto
          ),
          style: GoogleFonts.inter(fontSize: 14),
          validator: (value) {
            // Combina el validador existente con la nueva validación de longitud
            if (validator != null) {
              final error = validator(value);
              if (error != null) {
                return error;
              }
            }
            if (maxLength != null && value != null && value.length > maxLength) {
              return 'Máximo $maxLength caracteres';
            }
            return null; // No hay errores
          },
        ),
      ],
    );
  }

  Widget _buildDropdownField(
      String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged, {String? initialValue}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: initialValue,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          hint: Text('Selecciona $label', style: GoogleFonts.inter(fontSize: 14)),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item, style: GoogleFonts.inter(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
          style: GoogleFonts.inter(fontSize: 14, color: AppColors.textDark),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'Por favor selecciona un ${label.replaceAll('*', '').trim()}';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime initialDate, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          style: GoogleFonts.inter(fontSize: 14),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'Por favor selecciona una fecha';
            }
            if (value != null && value.isNotEmpty) {
              try {
                final selectedDate = DateTime.parse(value);
                final today = DateTime.now();
                if (selectedDate.isBefore(DateTime(today.year, today.month, today.day))) {
                  return 'La fecha no puede ser anterior a hoy';
                }
              } catch (e) {
                return 'Formato de fecha inválido';
              }
            }
            return null;
          },
          onTap: () async {
            final currentContext = context;
            DateTime? pickedDate = await showDatePicker(
              context: currentContext,
              initialDate: initialDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null && currentContext.mounted) {
              controller.text = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TimeOfDay initialTime, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 4),
        TextFormField(
          readOnly: true,
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            suffixIcon: const Icon(Icons.access_time),
          ),
          style: GoogleFonts.inter(fontSize: 14),
          validator: (value) {
            if (label.contains('*') && (value == null || value.isEmpty)) {
              return 'Por favor selecciona una hora';
            }
            if (_selectedStartTime != null && _selectedEndTime != null) {
              // Convert to minutes to compare easily
              final startMinutes = _selectedStartTime!.hour * 60 + _selectedStartTime!.minute;
              final endMinutes = _selectedEndTime!.hour * 60 + _selectedEndTime!.minute;

              if (endMinutes <= startMinutes) {
                 return 'La hora de fin debe ser posterior a la de inicio';
              }
            }
            return null;
          },
          onTap: () async {
            final currentContext = context;
            TimeOfDay? pickedTime = await showTimePicker(
              context: currentContext,
              initialTime: initialTime,
            );
            if (pickedTime != null && currentContext.mounted) {
              controller.text = pickedTime.format(currentContext);
              setState(() {
                if (label.contains('Inicio')) {
                  _selectedStartTime = pickedTime;
                } else if (label.contains('Fin')) {
                  _selectedEndTime = pickedTime;
                }
              });
            }
          },
        ),
      ],
    );
  }
}
