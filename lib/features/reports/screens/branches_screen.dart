import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../inventory/screens/inventory_screen.dart';
import '../../sales/screens/payments_screen.dart';
import '../services/reports_service.dart';
import 'reports_screen.dart';
import 'package:pv26/core/utils/currency_formatter.dart';
import '../services/branches_service.dart';

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
    
    final result = await BranchesService.getLocations();

      if (!mounted) return;

      final data = result['data'];

   
      if (result['success'] == true &&
          data is Map &&
          data['locations'] is List &&
          (data['locations'] as List).isNotEmpty) {

        setState(() {
          _branches = List.from(data['locations']);
          _isLoading = false;
        });

      } else {
        setState(() {
          _branches = [];
          _isLoading = false;
        });
      
    
    }
  }



  String _f(double value) => CurrencyFormatter.format(value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Sucursales y Cobros', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Desempeño Diario por Sede',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Consulta las ventas totales generadas el día de hoy.',
              style: GoogleFonts.outfit(fontSize: 14, color: theme.colorScheme.onSurface.withOpacity(0.5)),
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
                              Icon(Icons.storefront_outlined, size: 64, color: theme.dividerColor),
                              const SizedBox(height: 16),
                              Text(
                                'No hay sucursales registradas',
                                style: GoogleFonts.outfit(color: theme.dividerColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _branches.length,
                          itemBuilder: (context, index) {
                            final branch = _branches[index];
                            final branchId = (branch['_id'] ?? branch['id']).toString();
                            final dailyTotal =  (branch['todaySalesTotal'] ?? 0).toDouble();
                             
                          
                            // Assign consistent colors/icons for design
                            final List<Color> colors = [Colors.blueAccent, const Color(0xFF05e265), Colors.orangeAccent, Colors.purpleAccent];
                            final color = colors[index % colors.length];

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: theme.dividerColor.withOpacity(0.05)),
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
                                        child: Icon(Icons.store_rounded, color: color, size: 28),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              branch['name'],
                                              style: GoogleFonts.outfit(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
                                                color: theme.colorScheme.onSurface,
                                              ),
                                            ),
                                            Text(
                                              branch['address'] ?? 'Sin ubicación',
                                              style: GoogleFonts.outfit(
                                                fontSize: 13,
                                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Daily Total Display
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Ventas de Hoy',
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: theme.colorScheme.onSurface.withOpacity(0.4),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _f(dailyTotal),
                                            style: GoogleFonts.outfit(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF05e265),
                                            ),
                                          ),
                                        ],
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
                                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => InventoryScreen(branchId: branchId))),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _BranchActionButton(
                                          title: 'Detalle Reporte',
                                          icon: Icons.analytics_rounded,
                                          color: Colors.orange,
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(
                                              builder: (context) => ReportsScreen(
                                                // Assuming ReportsScreen can receive a branchId to filter
                                                showBranchFilter: true,
                                                branchId: branchId,
                                                branchName: branch['name']
                                              ),
                                            ));
                                          },
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
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
