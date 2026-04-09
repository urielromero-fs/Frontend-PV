import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../sales/screens/payments_screen.dart';
import '../services/reports_service.dart';

class BranchesScreen extends StatefulWidget {
  const BranchesScreen({super.key});

  @override
  State<BranchesScreen> createState() => _BranchesScreenState();
}

class _BranchesScreenState extends State<BranchesScreen> {
  List<dynamic> _branches = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoading = true);
    
    // Simulando carga de datos reales pero usando dummies por ahora
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _branches = [
          {
            'id': '1',
            'name': 'Sucursal Principal',
            'location': 'Centro Histórico, CDMX',
            'color': Colors.blueAccent,
            'icon': Icons.store_rounded,
          },
          {
            'id': '2',
            'name': 'Sucursal Norte',
            'location': 'San Pedro Garza García, NL',
            'color': const Color(0xFF05e265),
            'icon': Icons.storefront_rounded,
          },
          {
            'id': '3',
            'name': 'Sucursal Sur',
            'location': 'Zona Hotelera, Cancún',
            'color': Colors.orangeAccent,
            'icon': Icons.business_rounded,
          },
        ];
      });
    }
  }

  void _showAddBranchForm() {
    final nameController = TextEditingController();
    final locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Nueva Sucursal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Nombre de la Sucursal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: locationController,
              style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
              decoration: InputDecoration(
                labelText: 'Ubicación / Dirección',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement create branch service if available
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sucursal creada exitosamente (Simulado)')),
              );
              _loadBranches();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Crear Sucursal', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Sucursales', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gestión de Sedes',
                  style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddBranchForm,
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text('Nueva Sucursal', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05e265),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _branches.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.storefront_outlined, size: 64, color: Theme.of(context).dividerColor),
                              const SizedBox(height: 16),
                              Text(
                                'No hay sucursales registradas',
                                style: GoogleFonts.outfit(color: Theme.of(context).dividerColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _branches.length,
                          itemBuilder: (context, index) {
                            final branch = _branches[index];
                            final color = branch['color'] as Color;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: color.withOpacity(0.05),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Icon(branch['icon'], color: color, size: 32),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              branch['name'],
                                              style: GoogleFonts.outfit(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.onSurface,
                                              ),
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.location_on_rounded, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  branch['location'],
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF05e265).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Activa',
                                          style: GoogleFonts.outfit(
                                            color: const Color(0xFF05e265),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                  const Divider(),
                                  const SizedBox(height: 20),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _BranchActionButton(
                                          title: 'Inventario',
                                          icon: Icons.inventory_2_rounded,
                                          color: Colors.blueAccent,
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryScreen())),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _BranchActionButton(
                                          title: 'Cobros',
                                          icon: Icons.point_of_sale_rounded,
                                          color: const Color(0xFF05e265),
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PaymentsScreen())),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BranchActionButton({
    required this.title,
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
