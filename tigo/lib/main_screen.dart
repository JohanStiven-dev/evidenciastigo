import 'package:shared_preferences/shared_preferences.dart';
import 'package:tigo/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tigo/app_colors.dart';
import 'package:tigo/notificaciones_view.dart';
import 'package:tigo/calendario_view.dart';
import 'package:tigo/dashboard_view.dart';
import 'package:tigo/actividades_view.dart';
import 'package:tigo/form_view.dart';
import 'package:tigo/generic_view.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  String _selectedView = 'dashboard';
  String? _initialActivityFilter; // To hold the filter for ActividadesView
  late AnimationController _fabController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _setActiveLink(String view) {
    setState(() {
      _selectedView = view;
      _initialActivityFilter = null; // Clear filter on normal navigation
    });
    if (MediaQuery.of(context).size.width < 1024) {
      Navigator.of(context).pop(); // Close drawer on mobile
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _navigateToActivities(String status) {
    setState(() {
      _selectedView = 'actividades';
      _initialActivityFilter = status;
    });
  }

  Widget _renderView() {
    switch (_selectedView) {
      case 'dashboard':
        return DashboardView(onNavigateToActivities: _navigateToActivities);
      case 'actividades':
        final filter = _initialActivityFilter;
        // Clear the filter immediately after using it, so it doesn't persist
        if (_initialActivityFilter != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _initialActivityFilter = null;
            });
          });
        }
        return ActividadesView(initialStatus: filter);
      case 'actividades/nueva':
        return const FormView();
      case 'calendario':
        return const CalendarioView();
      case 'notificaciones':
        return const NotificacionesView();

      default:
        return const GenericView(title: 'Error');
    }
  }

  void showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1024;

    return Scaffold(
      appBar: isDesktop
          ? null // No app bar on desktop, sidebar is always visible
          : AppBar(
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: SvgPicture.asset(
                      'assets/logo_tigo.svg',
                      height: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('Evidencias Tigo', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                ),
              ),
              backgroundColor: Colors.transparent, // Make transparent to show gradient
              elevation: 0,
              iconTheme: const IconThemeData(color: Colors.white), // White icons
            ),
      drawer: isDesktop
          ? null
          : Drawer(
              child: _buildSidebar(context, isDesktop),
            ),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(context, isDesktop),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _renderView(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, bool isDesktop) {
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        border: isDesktop ? const Border(right: BorderSide(color: Colors.grey)) : null,
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.grey.withOpacitySafe(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Container(
            height: 180, // Increased height for better spacing
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacitySafe(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: SvgPicture.asset(
                        'assets/logo_tigo.svg',
                        height: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Evidencias Tigo',
                        style: GoogleFonts.outfit( // Changed to Outfit to match Login
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FutureBuilder<String?>(
                  future: SharedPreferences.getInstance().then((prefs) => prefs.getString('userRole')),
                  builder: (context, snapshot) {
                    final role = snapshot.data ?? 'Cargando...';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacitySafe(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacitySafe(0.2)),
                      ),
                      child: Text(
                        role,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  context,
                  'Dashboard',
                  'dashboard',
                  Icons.dashboard,
                ),
                _buildDrawerItem(
                  context,
                  'Actividades',
                  'actividades',
                  Icons.list_alt,
                ),
                _buildDrawerItem(
                  context,
                  'Calendario',
                  'calendario',
                  Icons.calendar_today,
                ),
                _buildDrawerItem(
                  context,
                  'Notificaciones',
                  'notificaciones',
                  Icons.notifications,
                ),

              ],
            ),
          ),
          const Divider(),
          _buildDrawerItem(
            context,
            'Cerrar Sesión',
            'logout',
            Icons.logout,
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey)),
            ),
            child: Text(
              'Timezone: America/Bogota',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, String viewName, IconData icon) {
    final isSelected = _selectedView == viewName;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : AppColors.textMuted),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : AppColors.textDark,
        ),
      ),
      tileColor: isSelected ? AppColors.primary.withOpacitySafe(0.1) : null,
      onTap: () {
        if (viewName == 'logout') {
          _logout();
        } else {
          _setActiveLink(viewName);
        }
      },
    );
  }
}