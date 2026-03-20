import 'package:flutter/material.dart';
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
          //print(provider.allProducts);
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

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a1a1a),
          title: Text(
            'Configuración de Perfil',
            style: GoogleFonts.poppins(
              color: Colors.white,
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
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF05e265)),
                    ),
                    prefixIcon: const Icon(Icons.person, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Correo Electrónico',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF05e265)),
                    ),
                    prefixIcon: const Icon(Icons.email, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nueva Contraseña (opcional)',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white.withAlpha(51)),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF05e265)),
                    ),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
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
                style: GoogleFonts.poppins(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
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
        );
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
          backgroundColor: const Color(0xFF1a1a1a),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.support_agent_rounded, color: Color(0xFF05e265)),
              const SizedBox(width: 12),
              Text(
                'Centro de Ayuda',
                style: GoogleFonts.outfit(
                  color: Colors.white,
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
                style: GoogleFonts.outfit(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
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
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Lunes a Viernes: 10:00 AM - 5:00 PM',
                            style: GoogleFonts.outfit(
                              color: Colors.white70,
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
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'uriel.romero@fstack.com.mx',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
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
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '+52 55 1234 5678',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
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
    print(metricData);

    Widget buildSidebar() {
      return Container(
        width: sidebarWidth,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF000000), Color(0xFF1a1a1a)],
          ),
          border: Border(
            right: BorderSide(color: Colors.white.withOpacity(0.05)),
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
                          width: 40,
                          height: 40,
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
                          child: const Icon(
                            Icons.eco,
                            color: Color(0xFF05e265),
                            size: 24,
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
                          width: 40,
                          height: 40,
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
                          child: const Icon(
                            Icons.eco,
                            color: Color(0xFF05e265),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Centli 🌿',
                          style: GoogleFonts.outfit(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
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
                                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
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
      backgroundColor: const Color(0xFF050505),
      appBar: isMobile
          ? AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
              elevation: 0,
              title: Row(
                children: [
                  const Icon(Icons.eco, color: Color(0xFF05e265)),
                  const SizedBox(width: 8),
                  Text(
                    'Centli',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold,color: Colors.white),
                  ),
                ],
              ),
              actions: [
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
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.8, -0.8),
                  radius: 1.5,
                  colors: [
                    Color(0xFF151515),
                    Color(0xFF050505),
                  ],
                ),
              ),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.all(isMobile ? 20 : 40),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Welcome Header
                        Text(
                          '¡Hola, $_userName!',
                          style: GoogleFonts.outfit(
                            fontSize: isMobile ? 28 : 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Bienvenido de nuevo a Centli ',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: isMobile ? 14 : 18,
                          ),
                        ),
                        const SizedBox(height: 32),

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

                        // Quick Actions Section
                        Text(
                          'Accesos Rápidos',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                            return GridView.count(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisCount: crossAxisCount,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: isMobile ? 1.5 : 2.5,
                              children: [
                                _DashboardCard(
                                  title: 'Punto de Venta',
                                  subtitle: 'Realiza cobros y genera tickets rápidamente',
                                  icon: Icons.point_of_sale_rounded,
                                  color: const Color(0xFF05e265),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsScreen())),
                                ),
                                _DashboardCard(
                                  title: 'Inventario',
                                  subtitle: 'Gestiona existencias y precios de productos',
                                  icon: Icons.inventory_rounded,
                                  color: const Color(0xFF2196F3),
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())),
                                ),
                                if (_isAdmin) ...[
                                  _DashboardCard(
                                    title: 'Analíticas',
                                    subtitle: 'Consulta el rendimiento de tu negocio',
                                    icon: Icons.bar_chart_rounded,
                                    color: const Color(0xFFFF9800),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportsScreen())),
                                  ),
                                  _DashboardCard(
                                    title: 'Equipo',
                                    subtitle: 'Administra los roles y accesos de usuarios',
                                    icon: Icons.supervised_user_circle_rounded,
                                    color: const Color(0xFF9C27B0),
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen())),
                                  ),
                                ],
                                _DashboardCard(
                                  title: 'Ayuda y Soporte',
                                  subtitle: 'Contacta a soporte técnico y consulta horarios',
                                  icon: Icons.support_agent_rounded,
                                  color: Colors.amber,
                                  onTap: _showSupportModal,
                                ),
                              ],
                            );
                          },
                        ),
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
                    color: isActive ? const Color(0xFF05e265) : Colors.white60,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive ? const Color(0xFF05e265) : Colors.white60,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: GoogleFonts.outfit(
                          color: isActive ? Colors.white : Colors.white60,
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
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: Colors.white,
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

class _DashboardCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.05),
              Colors.white.withOpacity(0.01),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: Colors.white54,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Acceder',
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 14),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
