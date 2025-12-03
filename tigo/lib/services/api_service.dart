import 'package:tigo/models/notificacion.dart';
import 'package:tigo/models/user.dart';
import 'package:tigo/models/bitacora.dart';
import 'package:tigo/models/evidencia.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tigo/models/actividad.dart';
import 'package:tigo/models/catalogo.dart';
import 'package:tigo/models/dashboard_summary.dart';
import 'package:tigo/utils/api_exception.dart';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart' show MediaType;

class ApiService {
  static const String _baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:3000/api/v2');

  // Placeholder for authentication token
  String? _authToken;

  void setAuthToken(String token) {
    _authToken = token;
  }

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final String decoded = utf8.decode(base64Url.decode(normalized));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      if (!payloadMap.containsKey('exp')) return true;

      final exp = payloadMap['exp'] * 1000; // Convert to milliseconds
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if expired or expiring within 30 seconds
      return now >= (exp - 30000);
    } catch (e) {
      return true; // Assume expired if invalid
    }
  }

  Future<bool> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) return false;

    final url = Uri.parse('$_baseUrl/auth/refresh');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        final newAccessToken = data['accessToken'];
        final newRefreshToken = data['refreshToken'];

        if (newAccessToken != null && newRefreshToken != null) {
          await prefs.setString('accessToken', newAccessToken);
          await prefs.setString('refreshToken', newRefreshToken);
          setAuthToken(newAccessToken);
          return true;
        }
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
    return false;
  }

  Future<Map<String, String>> _getHeaders({bool includeAuth = true}) async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };
    if (includeAuth) {
      if (_authToken == null) {
        final prefs = await SharedPreferences.getInstance();
        _authToken = prefs.getString('accessToken');
      }

      if (_authToken != null && _isTokenExpired(_authToken!)) {
        debugPrint('Token expired, attempting refresh...');
        final success = await _refreshToken();
        if (!success) {
          debugPrint('Token refresh failed.');
          // Optionally clear prefs or handle logout here, but throwing generic error for now
          // Ideally, we should trigger a logout flow.
          _authToken = null; // Clear invalid token
        }
      }

      if (_authToken != null) {
        headers['Authorization'] = 'Bearer $_authToken';
      }
    }
    return headers;
  }

  // --- Authentication ---
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(includeAuth: false),
        body: json.encode({'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);
      debugPrint('API Service - Login: Raw response data: $responseData');

      if (response.statusCode == 200 && responseData['success'] == true) {
        final userData = responseData['data'];
        final user = User.fromJson(userData);
        final accessToken = userData['accessToken'];
        final refreshToken = userData['refreshToken'];

        debugPrint('API Service - Login: accessToken: $accessToken');
        debugPrint('API Service - Login: refreshToken: $refreshToken');
        debugPrint('API Service - Login: userData: $userData');

        if (accessToken == null || refreshToken == null || userData == null) {
          debugPrint('API Service - Login: Missing accessToken, refreshToken or user data in response.');
          throw ApiException('Faltan datos de autenticación en la respuesta del servidor.', statusCode: response.statusCode);
        }

        setAuthToken(accessToken); // Set the token in ApiService for subsequent requests

        return {
          'user': user,
          'accessToken': accessToken,
          'refreshToken': refreshToken,
        };
      } else {
        final errorMessage = responseData['message'] ?? 'Error de inicio de sesión.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('API Service - Login: Error: $e');
      throw ApiException('Error de red o del servidor: $e');
    }
  }

  
  Future<List<User>> getUsersByRole(String role) async {
    final url = Uri.parse('$_baseUrl/users?rol=$role');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => User.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar usuarios.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching users by role: $e');
      throw ApiException('Error de red o del servidor al intentar cargar usuarios: $e');
    }
  }

  // --- Catalogo Operations ---
  Future<List<Catalogo>> getCatalogos(String tipo) async {
    final url = Uri.parse('$_baseUrl/catalogo/$tipo');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Catalogo.fromJson(json)).toList();
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar catálogos.';
        debugPrint('Failed to load catalogos: ${response.statusCode} - $errorMessage');
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    }
    catch (e) {
      debugPrint('Error fetching catalogos: $e');
      throw ApiException('Error de red o del servidor al intentar cargar catálogos: $e');
    }
  }

  // --- Actividad Operations ---
        Future<Map<String, dynamic>> getActividades({
          DateTime? startDate,
          DateTime? endDate,
          String? ciudad,
          String? canal,
          String? semana,
          String? status,
          String? subStatus, // Added subStatus parameter
          String? sort,
          String? order,
          int page = 1,
          int limit = 10,
        }) async {
          final Map<String, String> queryParams = {
            'page': page.toString(),
            'per_page': limit.toString(),
          };
          if (sort != null) {
            queryParams['sort'] = sort;
          }
          if (order != null) {
            queryParams['order'] = order;
          }
          if (startDate != null) {
            queryParams['fecha_desde'] = startDate.toIso8601String().split('T')[0];
          }
          if (endDate != null) {
            queryParams['fecha_hasta'] = endDate.toIso8601String().split('T')[0];
          }
          if (ciudad != null && ciudad.isNotEmpty) {
            queryParams['ciudad'] = ciudad;
          }
          if (canal != null && canal.isNotEmpty) {
            queryParams['canal'] = canal;
          }
          if (semana != null && semana.isNotEmpty) {
            queryParams['semana'] = semana;
          }
          if (status != null && status.isNotEmpty && status != 'Todas') {
            queryParams['status'] = status;
          }
          if (subStatus != null && subStatus.isNotEmpty && subStatus != 'Todas') {
            queryParams['sub_status'] = subStatus; // Add sub_status to query params
          }
        Uri url = Uri.parse('$_baseUrl/actividades');
        if (queryParams.isNotEmpty) {
          url = url.replace(queryParameters: queryParams);
        }      
      try {
        final response = await http.get(url, headers: await _getHeaders());
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseBody = json.decode(response.body);
          
          // Defensive check for the data object
          if (responseBody['data'] == null) {
            return {
              'actividades': <Actividad>[],
              'totalItems': 0,
              'totalPages': 0,
            };
          }

          final List<dynamic> actividadesData = responseBody['data']['data'] ?? [];
          // Backend returns metadata in 'meta' object
          final Map<String, dynamic> meta = responseBody['data']['meta'] ?? {};
          final int totalItems = meta['total'] ?? 0;
          final int totalPages = meta['total_pages'] ?? 0;

          final List<Actividad> actividades = actividadesData.map((json) => Actividad.fromJson(json)).toList();
          return {
            'actividades': actividades,
            'totalItems': totalItems,
            'totalPages': totalPages,
          };
        } else {
          final errorData = json.decode(response.body);
          final errorMessage = errorData['message'] ?? 'Error al cargar actividades.';
          debugPrint('Failed to load actividades: ${response.statusCode} - $errorMessage');
          throw ApiException(errorMessage, statusCode: response.statusCode);
        }
      } catch (e) {
        debugPrint('Error fetching actividades: $e');
        throw ApiException('Error de red o del servidor al intentar cargar actividades: $e');
      }
    }

  Future<Actividad?> getActividadById(int id) async {
    final url = Uri.parse('$_baseUrl/actividades/$id');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return Actividad.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar la actividad.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al cargar la actividad: $e');
    }
  }

  Future<Actividad?> createActividad(Actividad actividad) async {
    final url = Uri.parse('$_baseUrl/actividades');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(actividad.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Actividad.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al crear actividad.';
        debugPrint('Failed to create actividad: ${response.statusCode} - $errorMessage');
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Error creating actividad: $e');
      throw ApiException('Error de red o del servidor al intentar crear actividad: $e');
    }
  }

  Future<Actividad?> updateActividad(int id, Actividad actividad, {String? motivo}) async {
    final url = Uri.parse('$_baseUrl/actividades/$id');
    try {
      final Map<String, dynamic> body = actividad.toJson();
      if (motivo != null) {
        body['motivo'] = motivo;
      }
      final response = await http.put(
        url,
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Actividad.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al actualizar actividad.';
        debugPrint('Failed to update actividad: ${response.statusCode} - $errorMessage');
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Error updating actividad: $e');
      throw ApiException('Error de red o del servidor al intentar actualizar actividad: $e');
    }
  }


  Future<bool> changeActividadStatus(int id, String newStatus, String newSubStatus, {String? motivo}) async {
    final url = Uri.parse('$_baseUrl/actividades/$id/status');
    try {
      final body = {
        'newStatus': newStatus,
        'newSubStatus': newSubStatus,
        if (motivo != null) 'motivo': motivo,
      };
      final response = await http.patch(
        url,
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al actualizar estado de actividad.';
        debugPrint('Failed to change activity status: ${response.statusCode} - $errorMessage');
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Error changing activity status: $e');
      throw ApiException('Error de red o del servidor al intentar actualizar estado: $e');
    }
  }

  Future<bool> deleteActividad(int id) async {
    final url = Uri.parse('$_baseUrl/actividades/$id');
    try {
      final response = await http.delete(url, headers: await _getHeaders());
      if (response.statusCode == 204) { // No Content
        return true;
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al eliminar actividad.';
        debugPrint('Failed to delete actividad: ${response.statusCode} - $errorMessage');
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Error deleting actividad: $e');
      throw ApiException('Error de red o del servidor al intentar eliminar actividad: $e');
    }
  }

  // --- Dashboard Operations ---
  Future<DashboardSummary?> getDashboardSummary(DateTime startDate, DateTime endDate) async {
    final formattedStartDate = startDate.toIso8601String().split('T')[0];
    final formattedEndDate = endDate.toIso8601String().split('T')[0];
    final url = Uri.parse('$_baseUrl/dashboard/resumen?fecha_desde=$formattedStartDate&fecha_hasta=$formattedEndDate');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // The 'data' object from the response is passed directly to the factory constructor
        return DashboardSummary.fromJson(data['data']);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar el resumen del dashboard.';
        debugPrint('Failed to load dashboard summary: ${response.statusCode} - $errorMessage');
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Error fetching dashboard summary: $e');
      throw ApiException('Error de red o del servidor al intentar cargar el resumen del dashboard: $e');
    }
  }

  Future<List<Notificacion>> getNotificaciones() async {
    final url = Uri.parse('$_baseUrl/notificaciones');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Notificacion.fromJson(json)).toList();
      } else {
        throw ApiException('Error al cargar notificaciones', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al cargar notificaciones: $e');
    }
  }

  Future<void> markNotificacionAsRead(int id) async {
    final url = Uri.parse('$_baseUrl/notificaciones/$id/read');
    try {
      final response = await http.patch(url, headers: await _getHeaders());
      if (response.statusCode != 200) {
        throw ApiException(json.decode(response.body)['message'] ?? 'Error desconocido', statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error al marcar notificación como leída: $e');
    }
  }

  Future<void> deleteNotificacion(int id) async {
    final url = Uri.parse('$_baseUrl/notificaciones/$id');
    final response = await http.delete(url, headers: await _getHeaders());
    if (response.statusCode != 200) {
      throw ApiException(json.decode(response.body)['message'] ?? 'Error desconocido', statusCode: response.statusCode);
    }
  }

  Future<void> updateEvidenciaStatus(int id, String status, String? motivoRechazo) async {
    final url = Uri.parse('$_baseUrl/evidencias/$id/status');
    final response = await http.put(
      url,
      headers: await _getHeaders(),
      body: json.encode({
        'status': status,
        if (motivoRechazo != null) 'motivoRechazo': motivoRechazo,
      }),
    );

    if (response.statusCode == 200) {
      // Success, no need to return anything specific
      throw ApiException(json.decode(response.body)['message'] ?? 'Error desconocido', statusCode: response.statusCode);
    }
  }



  Future<List<Bitacora>> getBitacoraByActividadId(int actividadId) async {
    final url = Uri.parse('$_baseUrl/bitacoras/actividad/$actividadId');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body)['data'];
        final List<dynamic> data = (responseData is Map && responseData.containsKey('data')) 
            ? responseData['data'] 
            : responseData;
        return data.map((json) => Bitacora.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // No logs found
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar la bitácora.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al cargar la bitácora: $e');
    }
  }

  Future<List<Evidencia>> getEvidenciasByPresupuestoItemId(int presupuestoItemId) async {
    final url = Uri.parse('$_baseUrl/evidencias/presupuesto-item/$presupuestoItemId');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Evidencia.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // No evidence found
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar las evidencias.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al cargar las evidencias: $e');
    }
  }

  Future<List<Evidencia>> getEvidenciasByActividadId(int actividadId) async {
    final url = Uri.parse('$_baseUrl/evidencias/actividad/$actividadId');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((json) => Evidencia.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return []; // No evidence found
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar las evidencias de la actividad.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al cargar las evidencias: $e');
    }
  }

  Future<Evidencia> uploadEvidencia(int presupuestoItemId, Uint8List imageBytes, String fileName) async {
    final url = Uri.parse('$_baseUrl/evidencias');
    final request = http.MultipartRequest('POST', url);
    
    final headers = await _getHeaders();
    request.headers.addAll(headers);

    request.fields['presupuesto_item_id'] = presupuestoItemId.toString();
    request.fields['tipo'] = 'image';

    request.files.add(http.MultipartFile.fromBytes(
      'evidencia',
      imageBytes,
      filename: fileName,
      contentType: MediaType('image', _getFileExtension(fileName)),
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        return Evidencia.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al subir la evidencia.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al subir la evidencia: $e');
    }
  }

  Future<Presupuesto?> getPresupuestoByActividadId(int actividadId) async {
    final url = Uri.parse('$_baseUrl/presupuestos/actividad/$actividadId');
    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        if (data == null) return null; // Handle explicit null from backend
        return Presupuesto.fromJson(data);
      } else if (response.statusCode == 404) {
        return null; // No budget found for this activity
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al cargar el presupuesto.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al cargar el presupuesto: $e');
    }
  }

  Future<PresupuestoItem> addPresupuestoItem(int presupuestoId, Map<String, dynamic> itemData) async {
    final url = Uri.parse('$_baseUrl/presupuestos/$presupuestoId/items');
    try {
      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: json.encode(itemData),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        return PresupuestoItem.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al agregar ítem al presupuesto.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al agregar ítem: $e');
    }
  }

  Future<PresupuestoItem> updatePresupuestoItem(int itemId, Map<String, dynamic> itemData) async {
    final url = Uri.parse('$_baseUrl/presupuestos/items/$itemId');
    try {
      final response = await http.put(
        url,
        headers: await _getHeaders(),
        body: json.encode(itemData),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body)['data'];
        return PresupuestoItem.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al actualizar ítem del presupuesto.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al actualizar ítem: $e');
    }
  }

  Future<void> deletePresupuestoItem(int itemId) async {
    final url = Uri.parse('$_baseUrl/presupuestos/items/$itemId');
    try {
      final response = await http.delete(url, headers: await _getHeaders());

      if (response.statusCode != 200) {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al eliminar ítem del presupuesto.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al eliminar ítem: $e');
    }
  }

  Future<Uint8List> exportActividadesToXlsx({
    DateTime? startDate,
    DateTime? endDate,
    String? ciudad,
    String? canal,
    String? status,
    String? subStatus, // Added subStatus parameter
  }) async {
    final Map<String, String> queryParams = {};
    if (startDate != null) {
      queryParams['fecha_desde'] = startDate.toIso8601String().split('T')[0];
    }
    if (endDate != null) {
      queryParams['fecha_hasta'] = endDate.toIso8601String().split('T')[0];
    }
    if (ciudad != null && ciudad.isNotEmpty) {
      queryParams['ciudad'] = ciudad;
    }
    if (canal != null && canal.isNotEmpty) {
      queryParams['canal'] = canal;
    }
    if (status != null && status.isNotEmpty && status != 'Todas') {
      queryParams['status'] = status;
    }
    if (subStatus != null && subStatus.isNotEmpty && subStatus != 'Todas') {
      queryParams['sub_status'] = subStatus; // Add sub_status to query params
    }

    Uri url = Uri.parse('$_baseUrl/reportes/actividades.xlsx');
    if (queryParams.isNotEmpty) {
      url = url.replace(queryParameters: queryParams);
    }

    try {
      final response = await http.get(url, headers: await _getHeaders());
      if (response.statusCode == 200) {
        return response.bodyBytes; // Return binary data
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al exportar el archivo Excel.';
        debugPrint('Failed to export activities to XLSX: ${response.statusCode} - $errorMessage');
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('Error exporting activities to XLSX: $e');
      throw ApiException('Error de red o del servidor al intentar exportar el archivo Excel: $e');
    }
  }

  Future<String> uploadOC(int presupuestoId, Uint8List fileBytes, String fileName) async {
    final url = Uri.parse('$_baseUrl/presupuestos/$presupuestoId/oc');
    final request = http.MultipartRequest('POST', url);
    
    final headers = await _getHeaders();
    request.headers.addAll(headers);

    request.files.add(http.MultipartFile.fromBytes(
      'evidencia', // Corrected to match backend middleware
      fileBytes,
      filename: fileName,
      contentType: MediaType('application', 'pdf'), // Assuming PDF or generic
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body)['data'];
        return data['archivo_oc'];
      } else {
        final errorData = json.decode(response.body);
        final errorMessage = errorData['message'] ?? 'Error al subir la OC.';
        throw ApiException(errorMessage, statusCode: response.statusCode);
      }
    } catch (e) {
      throw ApiException('Error de red o del servidor al subir la OC: $e');
    }
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'png'; // Default to png if no extension found
  }
}