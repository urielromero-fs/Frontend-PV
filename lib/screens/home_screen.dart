import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'inventory_screen.dart';
import 'payments_screen.dart';
import 'reports_screen.dart';
import 'users_screen.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = '';
  String _userEmail = '';
  bool _isSidebarCollapsed = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = prefs.getString('user_name') ?? '';
    final userEmail = prefs.getString('user_email') ?? '';
    
    setState(() {
      _userName = userName;
      _userEmail = userEmail;
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
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Actualiza tus datos de acceso.', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Nombre Completo',
                    labelStyle: GoogleFonts.poppins(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(51))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF05e265))),
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
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(51))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF05e265))),
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
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withAlpha(51))),
                    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: const Color(0xFF05e265))),
                    prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: GoogleFonts.poppins(color: Colors.white54)),
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
                // La contraseña se enviaría al backend en un caso real.
                
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
              child: Text('Guardar', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: sidebarWidth,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF000000),
                  const Color(0xFF1a1a1a),
                ],
              ),
            ),
            child: Column(
              children: [
                // Logo/Brand
                Container(
                  padding: EdgeInsets.all(_isSidebarCollapsed ? 16 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: const [Color(0xFF05e265), Color(0xFF04c457)],
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
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.store,
                                color: Color(0xFF05e265),
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isSidebarCollapsed = !_isSidebarCollapsed;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  // Increased visibility: More opaque background
                                  color: const Color(0xFF05e265).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF05e265),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.menu_open, // Shows arrow pointing right to expand
                                  color: Colors.white, // White icon for better contrast on green bg
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.store,
                                    color: Color(0xFF05e265),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'PV26',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isSidebarCollapsed = !_isSidebarCollapsed;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF05e265).withAlpha(51),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF05e265),
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      _isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                                      color: const Color(0xFF05e265),
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
                
                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _NavItem(
                        icon: Icons.dashboard,
                        title: 'Dashboard',
                        isActive: true,
                        isCollapsed: _isSidebarCollapsed,
                      ),
                      _NavItem(
                        icon: Icons.inventory_2,
                        title: 'Inventario',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InventoryScreen(),
                            ),
                          );
                        },
                        isCollapsed: _isSidebarCollapsed,
                      ),
                      _NavItem(
                        icon: Icons.payment,
                        title: 'Cobros',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PaymentsScreen(),
                            ),
                          );
                        },
                        isCollapsed: _isSidebarCollapsed,
                      ),
                      _NavItem(
                        icon: Icons.analytics,
                        title: 'Reportes',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ReportsScreen(),
                            ),
                          );
                        },
                        isCollapsed: _isSidebarCollapsed,
                      ),
                      _NavItem(
                        icon: Icons.people,
                        title: 'Usuarios',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const UsersScreen(),
                            ),
                          );
                        },
                        isCollapsed: _isSidebarCollapsed,
                      ),
                      const Divider(color: Colors.white24),
                      _NavItem(
                        icon: Icons.settings,
                        title: 'Configuración',
                        onTap: () {
                          _showSettingsModal();
                        },
                        isCollapsed: _isSidebarCollapsed,
                      ),
                    ],
                  ),
                ),
                
                // User Profile
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.1)),
                    ),
                  ),
                  child: _isSidebarCollapsed
                      ? Center(
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white70),
                            onPressed: () async {
                              final result = await AuthService.logout();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      result['message'] ?? 'Sesión cerrada',
                                      style: GoogleFonts.poppins(),
                                    ),
                                    backgroundColor: result['success'] == true
                                        ? const Color(0xFF05e265)
                                        : Colors.red,
                                  ),
                                );
                                Navigator.pushReplacementNamed(context, '/login');
                              }
                            },
                          ),
                        )
                      : Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFF05e265),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _userName,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _userEmail,
                                    style: GoogleFonts.poppins(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.white70),
                              onPressed: () async {
                                final result = await AuthService.logout();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result['message'] ?? 'Sesión cerrada',
                                        style: GoogleFonts.poppins(),
                                      ),
                                      backgroundColor: result['success'] == true
                                          ? const Color(0xFF05e265)
                                          : Colors.red,
                                    ),
                                  );
                                  Navigator.pushReplacementNamed(context, '/login');
                                }
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          
          // Main Content Area
          // Expanded(
          //   child: Container(
          //     decoration: BoxDecoration(
          //       color: const Color(0xFF0a0a0a),
          //     ),
          //     child: Column(
          //       children: [
          //         // Header
          //         Container(
          //           padding: const EdgeInsets.all(16),
          //           decoration: BoxDecoration(
          //             color: const Color(0xFF000000),
          //             border: Border(
          //               bottom: BorderSide(color: Colors.white.withAlpha(26)),
          //             ),
          //           ),
          //           child: Row(
          //             children: [
          //               // Title
          //               Expanded(
          //                 child: Text(
          //                   'Dashboard',
          //                   style: GoogleFonts.poppins(
          //                     fontSize: 24,
          //                     fontWeight: FontWeight.bold,
          //                     color: Colors.white,
          //                   ),
          //                 ),
          //               ),
                        
          //               // User Info
          //               Container(
          //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          //                 decoration: BoxDecoration(
          //                   color: Colors.white.withAlpha(13),
          //                   borderRadius: BorderRadius.circular(20),
          //                 ),
          //                 child: Row(
          //                   children: [
          //                     const Icon(Icons.person, color: Colors.white70, size: 16),
          //                     const SizedBox(width: 8),
          //                     Text(
          //                       _userName,
          //                       style: GoogleFonts.poppins(
          //                         color: Colors.white,
          //                         fontSize: 14,
          //                       ),
          //                     ),
          //                   ],
          //                 ),
          //               ),
          //               const SizedBox(width: 16),
          //               IconButton(
          //                 icon: const Icon(Icons.logout, color: Colors.white70),
          //                 onPressed: () async {
          //                   final result = await AuthService.logout();
          //                   if (context.mounted) {
          //                     ScaffoldMessenger.of(context).showSnackBar(
          //                       SnackBar(
          //                         content: Text(
          //                           result['message'] ?? 'Sesión cerrada',
          //                           style: GoogleFonts.poppins(),
          //                         ),
          //                         backgroundColor: result['success'] == true
          //                             ? const Color(0xFF05e265)
          //                             : Colors.red,
          //                       ),
          //                     );
          //                     Navigator.pushReplacementNamed(context, '/login');
          //                   }
          //                 },
          //               ),
          //             ],
          //           ),
          //         ),
                  
          //         // Dashboard Content
          //         Expanded(
          //           child: Padding(
          //             padding: const EdgeInsets.all(24),
          //             child: Column(
          //               crossAxisAlignment: CrossAxisAlignment.start,
          //               children: [
          //                 // Welcome Message
          //                 Text(
          //                   'Bienvenido, ${_userName}',
          //                   style: GoogleFonts.poppins(
          //                     fontSize: 32,
          //                     fontWeight: FontWeight.bold,
          //                     color: Colors.white,
          //                   ),
          //                 ),
          //                 const SizedBox(height: 8),
          //                 Text(
          //                   'Aquí está el resumen de tu negocio',
          //                   style: GoogleFonts.poppins(
          //                     color: Colors.white70,
          //                     fontSize: 16,
          //                   ),
          //                 ),
          //                 const SizedBox(height: 32),
                          
          //                 // Stats Grid
          //                 // Row(
          //                 //   children: [
          //                 //     Expanded(
          //                 //       child: _StatCard(
          //                 //         title: 'Ventas Hoy',
          //                 //         value: '\$12,450',
          //                 //         icon: Icons.trending_up,
          //                 //         color: const Color(0xFF05e265),
          //                 //         change: '+12.5%',
          //                 //       ),
          //                 //     ),
          //                 //     const SizedBox(width: 16),
          //                 //     Expanded(
          //                 //       child: _StatCard(
          //                 //         title: 'Productos',
          //                 //         value: '248',
          //                 //         icon: Icons.inventory,
          //                 //         color: const Color(0xFF2196F3),
          //                 //         change: '+5',
          //                 //       ),
          //                 //     ),
          //                 //     const SizedBox(width: 16),
          //                 //     Expanded(
          //                 //       child: _StatCard(
          //                 //         title: 'Clientes',
          //                 //         value: '1,426',
          //                 //         icon: Icons.people,
          //                 //         color: const Color(0xFFFF9800),
          //                 //         change: '+28',
          //                 //       ),
          //                 //     ),
          //                 //   ],
          //                 // ),
                        
          //                 LayoutBuilder(
          //                   builder: (context, constraints) {
          //                     final isMobile = constraints.maxWidth < 768;
          //                     return isMobile
          //                         ? Column(
          //                             children: [
          //                               _StatCard(
          //                                 title: 'Ventas Hoy',
          //                                 value: '\$12,450',
          //                                 icon: Icons.trending_up,
          //                                 color: const Color(0xFF05e265),
          //                                 change: '+12.5%',
          //                               ),
          //                               const SizedBox(height: 16),
          //                               _StatCard(
          //                                 title: 'Productos',
          //                                 value: '248',
          //                                 icon: Icons.inventory,
          //                                 color: const Color(0xFF2196F3),
          //                                 change: '+5',
          //                               ),
          //                               const SizedBox(height: 16),
          //                               _StatCard(
          //                                 title: 'Clientes',
          //                                 value: '1,426',
          //                                 icon: Icons.people,
          //                                 color: const Color(0xFFFF9800),
          //                                 change: '+28',
          //                               ),
          //                             ],
          //                           )
          //                         : Row(
          //                             children: [
          //                               Expanded(
          //                                 child: _StatCard(
          //                                   title: 'Ventas Hoy',
          //                                   value: '\$12,450',
          //                                   icon: Icons.trending_up,
          //                                   color: const Color(0xFF05e265),
          //                                   change: '+12.5%',
          //                                 ),
          //                               ),
          //                               const SizedBox(width: 16),
          //                               Expanded(
          //                                 child: _StatCard(
          //                                   title: 'Productos',
          //                                   value: '248',
          //                                   icon: Icons.inventory,
          //                                   color: const Color(0xFF2196F3),
          //                                   change: '+5',
          //                                 ),
          //                               ),
          //                               const SizedBox(width: 16),
          //                               Expanded(
          //                                 child: _StatCard(
          //                                   title: 'Clientes',
          //                                   value: '1,426',
          //                                   icon: Icons.people,
          //                                   color: const Color(0xFFFF9800),
          //                                   change: '+28',
          //                                 ),
          //                               ),
          //                             ],
          //                           );
          //                   },
          //                 ),
                        
                        
          //               ],
          //             ),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),
          // ),
        
          // Main Content Area
Expanded(
  child: Container(
    color: const Color(0xFF0a0a0a),
    child: Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF000000),
            border: Border(
              bottom: BorderSide(color: Colors.white.withAlpha(26)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, color: Colors.white70, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _userName,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable Dashboard Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome
                    Text(
                      'Bienvenido, $_userName',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Aquí está el resumen de tu negocio',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Responsive Stats
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 768;

                        if (isMobile) {
                          return Column(
                            children: [
                              _StatCard(
                                title: 'Ventas Hoy',
                                value: '\$12,450',
                                icon: Icons.trending_up,
                                color: const Color(0xFF05e265),
                                change: '+12.5%',
                              ),
                              const SizedBox(height: 16),
                              _StatCard(
                                title: 'Productos',
                                value: '248',
                                icon: Icons.inventory,
                                color: const Color(0xFF2196F3),
                                change: '+5',
                              ),
                              const SizedBox(height: 16),
                              _StatCard(
                                title: 'Clientes',
                                value: '1,426',
                                icon: Icons.people,
                                color: const Color(0xFFFF9800),
                                change: '+28',
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Ventas Hoy',
                                value: '\$12,450',
                                icon: Icons.trending_up,
                                color: const Color(0xFF05e265),
                                change: '+12.5%',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Productos',
                                value: '248',
                                icon: Icons.inventory,
                                color: const Color(0xFF2196F3),
                                change: '+5',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _StatCard(
                                title: 'Clientes',
                                value: '1,426',
                                icon: Icons.people,
                                color: const Color(0xFFFF9800),
                                change: '+28',
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
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
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCollapsed ? 8 : 16, 
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF05e265).withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive 
          ? Border.all(color: const Color(0xFF05e265))
          : null,
      ),
      child: isCollapsed
          ? Icon(
              icon,
              color: isActive ? const Color(0xFF05e265) : Colors.white70,
              size: 20,
            )
          : Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? const Color(0xFF05e265) : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: isActive ? const Color(0xFF05e265) : Colors.white70,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
    );

    if (isCollapsed) {
      return Tooltip(
        message: title,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: content,
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: content,
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
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.poppins(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Abrir',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}