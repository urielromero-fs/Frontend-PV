import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:pv26/features/inventory/screens/inventory_screen.dart';
import 'package:pv26/features/sales/screens/payments_screen.dart';
import 'package:pv26/features/reports/screens/reports_screen.dart';
import 'package:pv26/features/users/screens/users_screen.dart';
import 'package:pv26/features/auth/services/auth_service.dart';
import 'package:pv26/features/inventory/providers/product_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../reports/services/reports_service.dart';
import 'package:pv26/core/providers/theme_provider.dart';
import '../../users/services/users_service.dart'; 
import '../../../core/utils/currency_formatter.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userRole = 'cajero'; // Default restriction
  bool _isSidebarCollapsed = false;

  bool get _isAdmin => _userRole.toLowerCase() == 'admin' || _userRole.toLowerCase() == 'administrador';
  bool get _isCajero => _userRole.toLowerCase() == 'seller' || _userRole.toLowerCase() == 'cajero';

   Map<String, dynamic> metricData = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
      // Carga inicial de productos
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProductProvider>(context, listen: false); 
         
      if (provider.allProducts.isEmpty) {
          provider.fetchInitialProducts();    
      }
      
    });

    _loadMetrics(); 
  }


   


  
  
  
  Future<void> _loadMetrics() async{


    final result = await ReportsService.getReport(period: 'day');


    if(result['success']){

      final data = result['data'];
      final actualReport = data['actualReport'] ?? {};
      final growth = data['growth'] ?? {};

      String formatCurrency(dynamic value) {
        if (value == null) return '\$0';
        final num number = value is num ? value : num.tryParse(value.toString()) ?? 0;
        return '\$${number.round()}';
      }

      String formatNumber(dynamic value) {
        if (value == null) return '0';
        final num number = value is num ? value : num.tryParse(value.toString()) ?? 0;
        return number.round().toString();
      }

      String formatChange(dynamic value) {
        if (value == null) return '0%';
        final num number = value is num ? value : num.tryParse(value.toString()) ?? 0;
        final int rounded = number.round();

        return rounded >= 0 ? '+$rounded%' : '$rounded%';
      }


      Map<String, dynamic> mappedData = {
        'ventas': formatCurrency(actualReport['totalSales']),
        'productos': formatNumber(actualReport['productsSold']),
        'ventas_change': formatChange(growth['salesGrowth']),
        'products_change': formatChange(growth['productsGrowth'] ?? 0),
     
      };


        setState(() {
          metricData = mappedData;
        });

    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al cargar datos'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }





  }


  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? '';
    final userEmail = prefs.getString('user_email') ?? '';
    final userRole = prefs.getString('user_role') ?? 'cajero';

    setState(() {
      _userName = userName;
      _userEmail = userEmail;
      _userRole = userRole;
    });
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  void _showSettingsModal() {
    final nameController = TextEditingController(text: _userName);
    final emailController = TextEditingController(text: _userEmail);
    final passwordController = TextEditingController();

    Future<void> saveSettings() async {
      setState(() {
        _userName = nameController.text;
        _userEmail = emailController.text;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userName);
      await prefs.setString('user_email', _userEmail);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado exitosamente'),
            backgroundColor: Color(0xFF05e265),
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return Focus(
          autofocus: false,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
              saveSettings();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
          title: Text(
            'Configuración de Perfil',
            style: GoogleFonts.poppins(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Actualiza tus datos de acceso.',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  autofocus: true,
                  controller: nameController,
                  onSubmitted: (_) => saveSettings(),
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF05e265)),
                    ),
                    prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  onSubmitted: (_) => saveSettings(),
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF05e265)),
                    ),
                    prefixIcon: Icon(Icons.email, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  onSubmitted: (_) => saveSettings(),
                  obscureText: true,
                  style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)',
                    labelStyle: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF05e265)),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final email = emailController.text.trim();
                final password = passwordController.text.trim();

                // Regex simple para email
                final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');

                // Validar email solo si viene con valor
                if (email.isNotEmpty && !emailRegex.hasMatch(email)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Correo electrónico inválido'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // Validar password solo si se escribe
                if (password.isNotEmpty && password.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('La contraseña debe tener al menos 8 caracteres'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // Loader
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(child: CircularProgressIndicator()),
                );

                final result = await UsersService.updateAdminUser(
                  name: name.isNotEmpty ? name : null,
                  email: email.isNotEmpty ? email : null,
                  password: password.isNotEmpty ? password : null,
                );

                Navigator.pop(context); // cerrar loader

                if (result['success']) {
                  // Solo actualizar lo que cambió
                  setState(() {
                    if (name.isNotEmpty) _userName = name;
                    if (email.isNotEmpty) _userEmail = email;
                  });

                  final prefs = await SharedPreferences.getInstance();
                  if (name.isNotEmpty) {
                    await prefs.setString('user_name', name);
                  }
                  if (email.isNotEmpty) {
                    await prefs.setString('user_email', email);
                  }

                  if (context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(result['message'] ?? 'Perfil actualizado'),
                        backgroundColor: const Color(0xFF05e265),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Error al actualizar'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05e265),
              ),
              child: Text(
                'Guardar',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ));
      },
    );
  }

  Future<void> _launchURL(Uri uri) async {
    try {
      // Para mailto es mejor usar platformDefault, para WhatsApp externalApplication
      final LaunchMode mode = uri.scheme == 'mailto' 
          ? LaunchMode.platformDefault 
          : LaunchMode.externalApplication;

      final bool launched = await launchUrl(
        uri,
        mode: mode,
      );
      if (!launched && context.mounted) {
        throw 'No se pudo abrir';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se encontró una aplicación compatible'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSupportModal() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: Color(0xFF05e265)),
              const SizedBox(width: 12),
              Text(
                'Centro de Ayuda',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estamos aquí para apoyarte con cualquier duda o problema técnico.',
                style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Horario de Atención',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lunes a Viernes: 10:00 AM - 5:00 PM',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.email_outlined, color: Colors.blue, size: 20),
                ),
                title: Text(
                  'Correo Electrónico',
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'uriel.romero@fstack.com.mx',
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                ),
                onTap: () {
                  final Uri emailUri = Uri(
                    scheme: 'mailto',
                    path: 'uriel.romero@fstack.com.mx',
                    queryParameters: {
                      'subject': 'Soporte Centli POS',
                      'body': 'Hola, necesito ayuda con...',
                    },
                  );
                  _launchURL(emailUri);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.chat_outlined, color: Colors.green, size: 20),
                ),
                title: Text(
                  'WhatsApp Soporte',
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '+52 55 1234 5678',
                  style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12),
                ),
                onTap: () {
                  final Uri whatsappUri = Uri.parse('https://wa.me/525512345678?text=Hola,%20necesito%20soporte%20con%20Centli%20POS.');
                  _launchURL(whatsappUri);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: GoogleFonts.outfit(color: const Color(0xFF05e265)),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final sidebarWidth = _isSidebarCollapsed ? 80.0 : 280.0;

    final provider = Provider.of<ProductProvider>(context); // listen: true por defecto
    final products = provider.allProducts; // List<dynamic> o List<Object>


    

    final productsEnStock = products
        .where((producto) => (producto as Map<String, dynamic>)['units'] > 5)
        .toList();

   final porcentageStock = products.isNotEmpty
    ? ((productsEnStock.length * 100) / products.length).round()
    : 0;


    Widget buildSidebar() {
      return Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            right: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.05)),
          ),
        ),
        child: Column(
          children: [
            // Logo/Brand
            Container(
              padding: EdgeInsets.all(_isSidebarCollapsed ? 16 : 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF05e265), Color(0xFF04c457)],
                ),
              ),
              child: _isSidebarCollapsed
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 12),
                        IconButton(
                          icon: const Icon(Icons.menu_open, color: Colors.white),
                          onPressed: () => setState(() => _isSidebarCollapsed = false),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          width: 180,
                          height: 50,
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          onPressed: () => setState(() => _isSidebarCollapsed = true),
                        ),
                      ],
                    ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                children: [
                  if (_isAdmin)
                    _NavItem(
                      icon: Icons.dashboard_rounded,
                      title: 'Dashboard',
                      isActive: true,
                      isCollapsed: _isSidebarCollapsed,
                      onTap: () {},
                    ),
                  _NavItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Inventario',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())),
                    isCollapsed: _isSidebarCollapsed,
                  ),
                  _NavItem(
                    icon: Icons.point_of_sale_rounded,
                    title: 'Cobros',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsScreen())),
                    isCollapsed: _isSidebarCollapsed,
                  ),
                  if (_isAdmin) ...[
                    _NavItem(
                      icon: Icons.people_alt_rounded,
                      title: 'Usuarios',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen())),
                      isCollapsed: _isSidebarCollapsed,
                    ),
                    _NavItem(
                      icon: Icons.analytics_rounded,
                      title: 'Reportes',
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen())),
                      isCollapsed: _isSidebarCollapsed,
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: Colors.white10),
                  ),
                  if (_isAdmin)
                    _NavItem(
                      icon: Icons.settings_rounded,
                      title: 'Configuracion',
                      onTap: _showSettingsModal,
                      isCollapsed: _isSidebarCollapsed,
                    ),
                  _NavItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Ayuda y Soporte',
                    onTap: _showSupportModal,
                    isCollapsed: _isSidebarCollapsed,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.white10),
                  ),
                  // Botón de cambio de tema
                  ListTile(
                    onTap: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                    leading: Icon(
                      Provider.of<ThemeProvider>(context).isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.orange : Colors.indigoAccent,
                    ),
                    title: _isSidebarCollapsed 
                      ? null 
                      : Text(
                          Provider.of<ThemeProvider>(context).isDarkMode ? 'Modo Claro' : 'Modo Oscuro',
                          style: GoogleFonts.poppins(
                            color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                  ),
                ],
              ),
            ),

            // User Profile
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: _isSidebarCollapsed
                  ? IconButton(
                      icon: const Icon(Icons.logout_rounded, color: Colors.white54),
                      onPressed: () => _handleLogout(context),
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF05e265), width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Color(0xFF1a1a1a),
                            child: Icon(Icons.person, color: Colors.white70, size: 20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _userName,
                                style: GoogleFonts.outfit(
                                  color: Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                _isAdmin ? 'ADMINISTRADOR' : 'CAJERO',
                                style: GoogleFonts.outfit(color: const Color(0xFF05e265), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: Colors.white54, size: 20),
                          onPressed: () => _handleLogout(context),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: isMobile
          ? AppBar(
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.eco, color: Color(0xFF05e265)),
                  const SizedBox(width: 8),
                  Text(
                    'Centli',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Provider.of<ThemeProvider>(context).isDarkMode ? Icons.light_mode : Icons.dark_mode,
                    color: Provider.of<ThemeProvider>(context).isDarkMode ? Colors.orange : Colors.indigoAccent,
                  ),
                  onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70),
                  onPressed: () => _handleLogout(context),
                ),
              ],
            )
          : null,
      drawer: isMobile
          ? Drawer(
              backgroundColor: const Color(0xFF0a0a0a),
              child: Column(
                children: [
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF05e265), Color(0xFF04c457)],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.eco, color: Colors.white, size: 48),
                          const SizedBox(height: 8),
                          Text(
                            'Centli ',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _NavItem(
                          icon: Icons.dashboard_rounded,
                          title: 'Dashboard',
                          isActive: true,
                          onTap: () => Navigator.pop(context),
                        ),
                        _NavItem(
                          icon: Icons.inventory_2_rounded,
                          title: 'Inventario',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen()));
                          },
                        ),
                        _NavItem(
                          icon: Icons.point_of_sale_rounded,
                          title: 'Cobros',
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsScreen()));
                          },
                        ),
                        if (_isAdmin) ...[
                          _NavItem(
                            icon: Icons.people_alt_rounded,
                            title: 'Usuarios',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen()));
                            },
                          ),
                          _NavItem(
                            icon: Icons.analytics_rounded,
                            title: 'Reportes',
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen()));
                            },
                          ),
                        ],
                        const Divider(color: Colors.white10),
                        if (_isAdmin)
                          _NavItem(
                            icon: Icons.settings_rounded,
                            title: 'Configuracion',
                            onTap: () {
                              Navigator.pop(context);
                              _showSettingsModal();
                            },
                          ),
                        _NavItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Ayuda y Soporte',
                          onTap: () {
                            Navigator.pop(context);
                            _showSupportModal();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (!isMobile) buildSidebar(),
          Expanded(
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(isMobile ? 20 : 40),
                    sliver: SliverList(
                     delegate: SliverChildListDelegate([
                        // Logo 
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Center(
                                child: Container(
                                  width: isMobile ? 260 : 580,
                                  height: isMobile ? 60 : 80,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Image.asset(
                                    'assets/images/logo.png', 
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),

                            // Saludo
                            Text(
                              '¡Hola, $_userName!',
                              style: GoogleFonts.outfit(
                                fontSize: isMobile ? 28 : 40,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bienvenido de nuevo a Centli',
                              style: GoogleFonts.outfit(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: isMobile ? 14 : 18,
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                        if (_isAdmin) ...[
                          // Quick Stats Grid
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final crossAxisCount = constraints.maxWidth < 600 ? 1 : (constraints.maxWidth < 1000 ? 2 : 3);
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: isMobile ? 2.5 : 1.8,
                                children: [
                                  _StatCard(
                                    title: 'Ventas del Día',
                                    value: (metricData['ventas'] ?? 0).toString(),
                                    icon: Icons.trending_up_rounded,
                                    color: const Color(0xFF05e265),
                                    change: (metricData['ventas_change'] ?? 0).toString(),
                                  ),
                                  _StatCard(
                                    title: 'Productos en Stock',
                                    value: productsEnStock.length.toString(),
                                    icon: Icons.inventory_2_rounded,
                                    color: const Color(0xFF2196F3),
                                    change: '%' + porcentageStock.toString(),
                                  ),
                                  _StatCard(
                                    title: 'Productos Vendidos',
                                    value:  (metricData['productos'] ?? 0).toString(),
                                    icon: Icons.people_alt_rounded,
                                    color: const Color(0xFFFF9800),
                                    change: (metricData['products_change'] ?? 0).toString(),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                        ],


                        const SizedBox(height: 100), // Bottom padding for scroll
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final result = await AuthService.logout();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Sesión cerrada', style: GoogleFonts.outfit()),
          backgroundColor: result['success'] == true ? const Color(0xFF05e265) : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isActive;
  final VoidCallback? onTap;
  final bool isCollapsed;

  const _NavItem({
    required this.icon,
    required this.title,
    this.isActive = false,
    this.onTap,
    this.isCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isCollapsed ? 8 : 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF05e265).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? const Color(0xFF05e265).withOpacity(0.3) : Colors.transparent,
            ),
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(
                    icon,
                    color: isActive ? const Color(0xFF05e265) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive ? const Color(0xFF05e265) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: isActive 
                            ? (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black)
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isActive)
                      Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF05e265),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.4 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF05e265).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF05e265),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

