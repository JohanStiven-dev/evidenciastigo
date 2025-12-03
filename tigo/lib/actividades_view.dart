import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:tigo/utils/api_exception.dart';
import 'package:tigo/utils/web_utils.dart' if (dart.library.io) 'package:tigo/utils/stub_web_utils.dart';
import 'package:tigo/change_status_popup.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/models/actividad.dart';
import 'package:tigo/models/catalogo.dart';
import 'package:tigo/services/api_service.dart';
import 'package:tigo/form_view.dart';
import 'package:tigo/activity_detail_view.dart';

class ActividadesView extends StatefulWidget {
  final String? initialStatus;
  const ActividadesView({super.key, this.initialStatus});

  @override
  State<ActividadesView> createState() => _ActividadesViewState();
}

class _ActividadesViewState extends State<ActividadesView> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Actividad> _actividades = [];
  List<Actividad> _filteredActividades = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _fechaDesdeController = TextEditingController();
  final TextEditingController _fechaHastaController = TextEditingController();
  final ScrollController _horizontalScrollController = ScrollController();

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String? _selectedCiudad;
  String? _selectedCanal;
  
  String _selectedMainStatus = 'Todas'; // Default to 'Todas'
  String? _selectedSubStatus = 'Todas'; // New filter for sub_status

  int? _sortColumnIndex;
  bool _sortAscending = true;

  List<Catalogo> _ciudades = [];
  List<Catalogo> _canales = [];
  bool _isLoadingCatalogs = true;
  String? _errorMessageCatalogs;

  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalItems = 0;
  int _totalPages = 1;

  final List<String> _mainStatusOptions = [
    'Todas',
    'Planificación',
    'Confirmada',
    'En Curso',
    'Finalizada',
  ];

  final Map<String, List<String>> _subStatusOptionsMap = {
    'Todas': ['Todas'],
    'Planificación': ['Todas', 'Borrador', 'En Revisión', 'Rechazado'],
    'Confirmada': ['Todas', 'Programada'],
    'En Curso': ['Todas', 'En Ejecución', 'Cargando Evidencias'],
    'Finalizada': ['Todas', 'Completado', 'Cancelado'],
  };

  @override
  void initState() {
    super.initState();
    _setDefaultDates();

    if (widget.initialStatus != null) {
      _selectedMainStatus = widget.initialStatus!;
      _selectedSubStatus = 'Todas'; // Initialize sub-status filter
    }
    _fetchCatalogs();
    _fetchActividades(
      startDate: _selectedStartDate,
      endDate: _selectedEndDate,
      ciudad: _selectedCiudad,
      canal: _selectedCanal,
      status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
      subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
    );
    _searchController.addListener(_filterActividades);
  }

  void _setDefaultDates() {
    final now = DateTime.now();
    _selectedStartDate = DateTime(now.year, 1, 1);
    _selectedEndDate = DateTime(now.year, 12, 31);
    final DateFormat formatter = DateFormat('yyyy-MM-dd');
    _fechaDesdeController.text = formatter.format(_selectedStartDate!);
    _fechaHastaController.text = formatter.format(_selectedEndDate!);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterActividades);
    _searchController.dispose();
    _fechaDesdeController.dispose();
    _fechaHastaController.dispose();
    _horizontalScrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchActividades({
    DateTime? startDate,
    DateTime? endDate,
    String? ciudad,
    String? canal,
    String? status,
    String? subStatus, // Added subStatus parameter
  }) async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      debugPrint('ActividadesView Debug: Fetching with params:');
      debugPrint('  StartDate: $startDate');
      debugPrint('  EndDate: $endDate');
      debugPrint('  Status: $status');
      debugPrint('  SubStatus: $subStatus');
      debugPrint('  Page: $_currentPage');

      final Map<String, dynamic> responseData = await _apiService.getActividades(
        startDate: startDate,
        endDate: endDate,
        ciudad: ciudad,
        canal: canal,
        status: status,
        subStatus: subStatus, // Pass subStatus to API call
        page: _currentPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      setState(() {
        _actividades = responseData['actividades'];
        _filteredActividades = responseData['actividades'];
        _totalItems = responseData['totalItems'];
        _totalPages = responseData['totalPages'];
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error al cargar actividades: ${e is ApiException ? e.message : e.toString()}';
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error inesperado al cargar actividades: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchCatalogs() async {
    try {
      setState(() {
        _isLoadingCatalogs = true;
        _errorMessageCatalogs = null;
      });

      final fetchedCiudades = await _apiService.getCatalogos('ciudad');
      final fetchedCanales = await _apiService.getCatalogos('canal');

      if (!mounted) return;

      setState(() {
        _ciudades = fetchedCiudades;
        _canales = fetchedCanales;
        _isLoadingCatalogs = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessageCatalogs = 'Error al cargar catálogos: ${e is ApiException ? e.message : e.toString()}';
        _isLoadingCatalogs = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessageCatalogs = 'Error inesperado al cargar catálogos: $e';
        _isLoadingCatalogs = false;
      });
    }
  }

  void _filterActividades() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredActividades = _actividades.where((actividad) {
        return actividad.puntoVenta.toLowerCase().contains(query) ||
               actividad.direccion.toLowerCase().contains(query) ||
               actividad.codigos.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _exportXlsx() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final Uint8List fileBytes = await _apiService.exportActividadesToXlsx(
        startDate: _selectedStartDate,
        endDate: _selectedEndDate,
        ciudad: _selectedCiudad,
        canal: _selectedCanal,
        status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
        subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
      );

      if (kIsWeb) {
        exportFileWeb(
          fileBytes,
          'actividades_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La exportación a Excel solo está disponible en la web por ahora.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Actividades exportadas a Excel con éxito.'),
          backgroundColor: Colors.green,
        ),
      );
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al exportar Excel: ${e is ApiException ? e.message : e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error inesperado al exportar Excel.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSort<T>(int columnIndex, bool ascending, Comparable<T> Function(Actividad actividad) getField) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _filteredActividades.sort((a, b) {
        final aValue = getField(a);
        final bValue = getField(b);
        return ascending ? Comparable.compare(aValue, bValue) : Comparable.compare(bValue, aValue);
      });
    });
  }

  Widget _buildStatusBadge(String mainStatus, String? subStatus) {
    Color bgColor;
    Color textColor;
    String displayText = subStatus != null && subStatus != mainStatus ? '$mainStatus: $subStatus' : mainStatus;

    switch (mainStatus) {
      case 'Planificación':
        bgColor = AppColors.statusRegistradaBg; // Using Registrada color for planning
        textColor = AppColors.statusRegistradaText;
        break;
      case 'Confirmada':
        bgColor = AppColors.statusProgramadaBg; // Using Programada color for confirmed
        textColor = AppColors.statusProgramadaText;
        break;
      case 'En Curso':
        bgColor = AppColors.statusEjecucionBg; // Using Ejecución color for in progress
        textColor = AppColors.statusEjecucionText;
        break;
      case 'Finalizada':
        // Differentiate based on subStatus for Finalizada
        if (subStatus == 'Completado') {
          bgColor = AppColors.statusCerradaBg;
          textColor = AppColors.statusCerradaText;
        } else if (subStatus == 'Cancelado' || subStatus == 'Rechazado') {
          bgColor = AppColors.statusRechazadaBg;
          textColor = AppColors.statusRechazadaText;
        } else {
          bgColor = Colors.grey.shade200; // Default for Finalizada
          textColor = Colors.grey.shade800;
        }
        break;
      default:
        bgColor = Colors.grey.shade200;
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        displayText,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bandeja de Actividades',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    FutureBuilder<String?>(
                      future: SharedPreferences.getInstance().then((prefs) => prefs.getString('userRole')),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data == 'Comercial') {
                          return ElevatedButton.icon(
                            onPressed: () async {
                              final result = await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      height: MediaQuery.of(context).size.height * 0.8,
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
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Scaffold(
                                          appBar: AppBar(
                                            title: Text('Crear Nueva Actividad', style: GoogleFonts.inter(color: AppColors.textDark)),
                                            backgroundColor: Colors.white,
                                            elevation: 1,
                                            leading: IconButton(
                                              icon: const Icon(Icons.close, color: AppColors.textDark),
                                              onPressed: () => Navigator.of(context).pop(),
                                            ),
                                          ),
                                          body: const FormView(),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (result == true) {
                                _fetchActividades(
                                  startDate: _selectedStartDate,
                                  endDate: _selectedEndDate,
                                  ciudad: _selectedCiudad,
                                  canal: _selectedCanal,
                                );
                              }
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: Text('Nueva Actividad', style: GoogleFonts.inter(fontSize: 14)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Buscar por PDV, dirección o códigos...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          style: GoogleFonts.inter(fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ..._mainStatusOptions.map((status) {
                              return _buildFilterChip(
                                status,
                                _selectedMainStatus == status,
                                () {
                                  setState(() {
                                    _selectedMainStatus = status;
                                    _selectedSubStatus = 'Todas'; // Reset sub-status when main status changes
                                  });
                                },
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_selectedMainStatus != 'Todas' && _subStatusOptionsMap[_selectedMainStatus] != null && _subStatusOptionsMap[_selectedMainStatus]!.length > 1)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filtrar por Sub-Estado',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  ..._subStatusOptionsMap[_selectedMainStatus]!.map((subStatus) {
                                    return _buildFilterChip(
                                      subStatus,
                                      _selectedSubStatus == subStatus,
                                      () {
                                        setState(() {
                                          _selectedSubStatus = subStatus;
                                        });
                                      },
                                    );
                                  }),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        _isLoadingCatalogs
                            ? const Center(child: CircularProgressIndicator())
                            : _errorMessageCatalogs != null
                                ? Center(
                                    child: Text(
                                      _errorMessageCatalogs!,
                                      style: GoogleFonts.inter(color: Colors.red, fontSize: 16),
                                    ),
                                  )
                                : LayoutBuilder(
                                    builder: (context, constraints) {
                                      return GridView.count(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        crossAxisCount: constraints.maxWidth > 600 ? 3 : 1,
                                        mainAxisSpacing: 8,
                                        crossAxisSpacing: 8,
                                        childAspectRatio: constraints.maxWidth > 600 ? 3 : 5,
                                        children: [
                                          _buildDateField(
                                            'Fecha Desde',
                                            _fechaDesdeController,
                                            _selectedStartDate,
                                            (date) {
                                              setState(() {
                                                _selectedStartDate = date;
                                              });
                                            },
                                          ),
                                          _buildDateField(
                                            'Fecha Hasta',
                                            _fechaHastaController,
                                            _selectedEndDate,
                                            (date) {
                                              setState(() {
                                                _selectedEndDate = date;
                                              });
                                            },
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Ciudad',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                initialValue: _selectedCiudad,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                hint: Text('Seleccionar Ciudad', style: GoogleFonts.inter(fontSize: 14)),
                                                items: _ciudades
                                                    .map((ciudad) => DropdownMenuItem(
                                                          value: ciudad.valor,
                                                          child: Text(ciudad.valor, style: GoogleFonts.inter(fontSize: 14)),
                                                        ))
                                                    .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedCiudad = value;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Canal',
                                                style: GoogleFonts.inter(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: AppColors.textDark,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              DropdownButtonFormField<String>(
                                                initialValue: _selectedCanal,
                                                decoration: InputDecoration(
                                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                ),
                                                hint: Text('Seleccionar Canal', style: GoogleFonts.inter(fontSize: 14)),
                                                items: _canales
                                                    .map((canal) => DropdownMenuItem(
                                                          value: canal.valor,
                                                          child: Text(canal.valor, style: GoogleFonts.inter(fontSize: 14)),
                                                        ))
                                                    .toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    _selectedCanal = value;
                                                  });
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlinedButton(
                                onPressed: () {
                                  _exportXlsx();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.green,
                                  side: const BorderSide(color: Colors.green),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.file_download_outlined, size: 18),
                                    const SizedBox(width: 8),
                                    Text('Exportar Excel', style: GoogleFonts.inter(fontSize: 14)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              OutlinedButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedStartDate = null;
                                    _selectedEndDate = null;
                                    _selectedCiudad = null;
                                    _selectedCanal = null;
                                    _selectedMainStatus = 'Todas';
                                    _selectedSubStatus = 'Todas';
                                    _fechaDesdeController.clear();
                                    _fechaHastaController.clear();
                                    _currentPage = 1; // Reset page
                                  });
                                  _fetchActividades();
                                },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textDark,
                                  side: const BorderSide(color: Colors.grey),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text('Limpiar Filtros', style: GoogleFonts.inter(fontSize: 14)),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _currentPage = 1; // Reset page on filter
                                  });
                                  _fetchActividades(
                                    startDate: _selectedStartDate,
                                    endDate: _selectedEndDate,
                                    ciudad: _selectedCiudad,
                                    canal: _selectedCanal,
                                    status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
                                    subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                ),
                                child: Text('Aplicar Filtros', style: GoogleFonts.inter(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Activities Table
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Scrollbar(
                          thumbVisibility: true,
                          controller: _horizontalScrollController,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: _horizontalScrollController,
                            child: DataTable(
                              columnSpacing: 24,
                              dataRowMinHeight: 50,
                              dataRowMaxHeight: 60,
                              sortColumnIndex: _sortColumnIndex,
                              sortAscending: _sortAscending,
                              columns: [
                                DataColumn(label: Text('Código(s)', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                                DataColumn(label: Text('Agencia', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                                DataColumn(label: Text('PDV / Ciudad', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                                DataColumn(label: Text('Canal', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                                DataColumn(label: Text('Responsable Canal', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                                DataColumn(label: Text('Teléfono', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                                DataColumn(
                                  label: Text('Fecha / Horario', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                                  onSort: (columnIndex, ascending) {
                                    _onSort(columnIndex, ascending, (actividad) => actividad.fecha);
                                  },
                                ),
                                DataColumn(
                                  label: Text('Estado', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                                  onSort: (columnIndex, ascending) {
                                    _onSort(columnIndex, ascending, (actividad) => actividad.status);
                                  },
                                ),
                                DataColumn(
                                  label: Text('Sub-Estado', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted)),
                                  onSort: (columnIndex, ascending) {
                                    _onSort(columnIndex, ascending, (actividad) => actividad.subStatus ?? '');
                                  },
                                ),
                                DataColumn(label: Text('Acciones', style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: AppColors.textMuted))),
                              ],
                              rows: _filteredActividades.map((actividad) {
                                return DataRow(cells: [
                                  DataCell(Text(actividad.codigos, style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
                                  DataCell(Text(actividad.agencia, style: GoogleFonts.inter())),
                                  DataCell(Text('${actividad.puntoVenta} / ${actividad.ciudad}', style: GoogleFonts.inter())),
                                  DataCell(Text(actividad.canal, style: GoogleFonts.inter())),
                                  DataCell(Text(actividad.responsableCanal ?? '', style: GoogleFonts.inter())),
                                  DataCell(Text(actividad.celularResponsable ?? '', style: GoogleFonts.inter())),
                                  DataCell(Text('${actividad.fecha.toIso8601String().split('T')[0]} / ${actividad.horaInicio}-${actividad.horaFin}', style: GoogleFonts.inter())),
                                  DataCell(_buildStatusBadge(actividad.status, actividad.subStatus)),
                                  DataCell(Text(actividad.subStatus ?? '', style: GoogleFonts.inter())),
                                  DataCell(
                                    Row(
                                      children: [
                                        TextButton(
                                          onPressed: () async {
                                            final result = await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ActivityDetailView(actividad: actividad),
                                              ),
                                            );
                                            if (result == true) {
                                              _fetchActividades(
                                                startDate: _selectedStartDate,
                                                endDate: _selectedEndDate,
                                                ciudad: _selectedCiudad,
                                                canal: _selectedCanal,
                                                status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
                                                subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
                                              );
                                            }
                                          },
                                          child: Text('Ver Detalle', style: GoogleFonts.inter(color: AppColors.primary)),
                                        ),
                                        FutureBuilder<String?>(
                                          future: SharedPreferences.getInstance().then((prefs) => prefs.getString('userRole')),
                                          builder: (context, snapshot) {
                                            final role = snapshot.data;
                                            if (role == 'Comercial') {
                                              return Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (actividad.status == 'Planificación' && actividad.subStatus == 'Borrador')
                                                    TextButton(
                                                      onPressed: () async {
                                                        final bool? activityUpdated = await showDialog<bool>(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return Dialog(
                                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                              elevation: 0,
                                                              backgroundColor: Colors.transparent,
                                                              child: Container(
                                                                width: MediaQuery.of(context).size.width * 0.8,
                                                                height: MediaQuery.of(context).size.height * 0.8,
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
                                                                child: ClipRRect(
                                                                  borderRadius: BorderRadius.circular(16),
                                                                  child: Scaffold(
                                                                    appBar: AppBar(
                                                                      title: Text('Editar Actividad', style: GoogleFonts.inter(color: AppColors.textDark)),
                                                                      backgroundColor: Colors.white,
                                                                      elevation: 1,
                                                                      leading: IconButton(
                                                                        icon: const Icon(Icons.close, color: AppColors.textDark),
                                                                        onPressed: () => Navigator.of(context).pop(),
                                                                      ),
                                                                    ),
                                                                    body: FormView(actividadToEdit: actividad),
                                                                  ),
                                                                ),
                                                              ),
                                                            );
                                                          },
                                                        );
                                                        if (activityUpdated == true) {
                                                          _fetchActividades(
                                                            startDate: _selectedStartDate,
                                                            endDate: _selectedEndDate,
                                                            ciudad: _selectedCiudad,
                                                            canal: _selectedCanal,
                                                            status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
                                                            subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
                                                          );
                                                        }
                                                      },
                                                      child: Text('Editar', style: GoogleFonts.inter(color: Colors.green)),
                                                    ),
                                                  if (actividad.status == 'Planificación' && (actividad.subStatus == 'Borrador' || actividad.subStatus == 'Rechazado'))
                                                    TextButton(
                                                      onPressed: () async {
                                                        final bool? statusUpdated = await showDialog<bool>(
                                                          context: context,
                                                          builder: (BuildContext context) {
                                                            return ChangeStatusPopup(actividad: actividad);
                                                          },
                                                        );
                                                        if (statusUpdated == true) {
                                                          _fetchActividades(
                                                            startDate: _selectedStartDate,
                                                            endDate: _selectedEndDate,
                                                            ciudad: _selectedCiudad,
                                                            canal: _selectedCanal,
                                                            status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
                                                            subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
                                                          );
                                                        }
                                                      },
                                                      child: Text('Enviar a Revisión', style: GoogleFonts.inter(color: Colors.orange)),
                                                    ),
                                                ],
                                              );
                                            }
                                            return const SizedBox.shrink();
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Pagination Controls (Moved Inside Card)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Mostrando ${_totalItems == 0 ? 0 : (_currentPage - 1) * _pageSize + 1} - ${(_currentPage * _pageSize) > _totalItems ? _totalItems : (_currentPage * _pageSize)} de $_totalItems resultados',
                              style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.chevron_left),
                                  onPressed: _currentPage > 1
                                      ? () {
                                          setState(() {
                                            _currentPage--;
                                          });
                                          _fetchActividades(
                                            startDate: _selectedStartDate,
                                            endDate: _selectedEndDate,
                                            ciudad: _selectedCiudad,
                                            canal: _selectedCanal,
                                            status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
                                            subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
                                          );
                                        }
                                      : null,
                                ),
                                // Numbered Pagination
                                ...List.generate(_totalPages, (index) {
                                  final pageNumber = index + 1;
                                  if (pageNumber == 1 ||
                                      pageNumber == _totalPages ||
                                      (pageNumber >= _currentPage - 1 && pageNumber <= _currentPage + 1)) {
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          _currentPage = pageNumber;
                                        });
                                        _fetchActividades(
                                          startDate: _selectedStartDate,
                                          endDate: _selectedEndDate,
                                          ciudad: _selectedCiudad,
                                          canal: _selectedCanal,
                                          status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
                                          subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        margin: const EdgeInsets.symmetric(horizontal: 4),
                                        decoration: BoxDecoration(
                                          color: _currentPage == pageNumber ? AppColors.primary : Colors.transparent,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: _currentPage == pageNumber ? AppColors.primary : Colors.grey.shade300),
                                        ),
                                        child: Text(
                                          '$pageNumber',
                                          style: GoogleFonts.inter(
                                            color: _currentPage == pageNumber ? Colors.white : AppColors.textDark,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  } else if (pageNumber == _currentPage - 2 || pageNumber == _currentPage + 2) {
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Text('...', style: GoogleFonts.inter(color: Colors.grey)),
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                }),
                                IconButton(
                                  icon: const Icon(Icons.chevron_right),
                                  onPressed: _currentPage < _totalPages
                                      ? () {
                                          setState(() {
                                            _currentPage++;
                                          });
                                          _fetchActividades(
                                            startDate: _selectedStartDate,
                                            endDate: _selectedEndDate,
                                            ciudad: _selectedCiudad,
                                            canal: _selectedCanal,
                                            status: _selectedMainStatus == 'Todas' ? null : _selectedMainStatus,
                                            subStatus: _selectedSubStatus == 'Todas' ? null : _selectedSubStatus,
                                          );
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 12)),
        backgroundColor: isSelected ? AppColors.primary.withOpacitySafe(0.1) : Colors.white,
        side: BorderSide(color: isSelected ? AppColors.primary : Colors.grey.shade300),
        labelStyle: GoogleFonts.inter(
          color: isSelected ? AppColors.primary : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller, DateTime? selectedDate, Function(DateTime?) onDateSelected) {
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
          onTap: () async {
            final currentContext = context;
            DateTime? pickedDate = await showDatePicker(
              context: currentContext,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null && currentContext.mounted) {
              controller.text = '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
              onDateSelected(pickedDate);
            }
          },
        ),
      ],
    );
  }
}