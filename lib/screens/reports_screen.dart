import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Este Día';

  // Dummy data arrays based on period
  Map<String, Map<String, String>> metricData = {
    'Este Día': {
      'ventas': '\$1,230',
      'ordenes': '45',
      'clientes': '12',
      'ticket': '\$115',
      'ventas_change': '+5%',
      'ordenes_change': '+2%',
      'clientes_change': '+1%',
      'ticket_change': '+3%',
    },
    'Esta Semana': {
      'ventas': '\$8,450',
      'ordenes': '150',
      'clientes': '35',
      'ticket': '\$122',
      'ventas_change': '+12%',
      'ordenes_change': '+8%',
      'clientes_change': '+5%',
      'ticket_change': '+4%',
    },
    'Este Mes': {
      'ventas': '\$45,230',
      'ordenes': '342',
      'clientes': '67',
      'ticket': '\$132',
      'ventas_change': '+23%',
      'ordenes_change': '+18%',
      'clientes_change': '+12%',
      'ticket_change': '+5%',
    },
  };

  void _showPeriodSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1a1a1a),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seleccionar Período',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildPeriodOption('Este Día'),
              _buildPeriodOption('Esta Semana'),
              _buildPeriodOption('Este Mes'),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodOption(String period) {
    return ListTile(
      title: Text(
        period,
        style: GoogleFonts.poppins(
          color: _selectedPeriod == period
              ? const Color(0xFFFF9800)
              : Colors.white70,
          fontWeight: _selectedPeriod == period
              ? FontWeight.bold
              : FontWeight.normal,
        ),
        textAlign: TextAlign.center,
      ),
      onTap: () {
        setState(() {
          _selectedPeriod = period;
        });
        Navigator.pop(context);
      },
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando y descargando reporte de $_selectedPeriod...'),
        backgroundColor: const Color(0xFF05e265),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentData = metricData[_selectedPeriod]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reportes',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF000000),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportReport,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF000000), const Color(0xFF1a1a1a)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period Selector
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(13),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withAlpha(26)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Período: $_selectedPeriod',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _showPeriodSelector,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Cambiar',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Key Metrics
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Ventas Totales',
                      value: currentData['ventas']!,
                      icon: Icons.trending_up,
                      color: const Color(0xFF05e265),
                      change: currentData['ventas_change']!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Órdenes',
                      value: currentData['ordenes']!,
                      icon: Icons.receipt,
                      color: const Color(0xFF2196F3),
                      change: currentData['ordenes_change']!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Clientes Nuevos',
                      value: currentData['clientes']!,
                      icon: Icons.person_add,
                      color: const Color(0xFFFF9800),
                      change: currentData['clientes_change']!,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Ticket Promedio',
                      value: currentData['ticket']!,
                      icon: Icons.attach_money,
                      color: const Color(0xFF9C27B0),
                      change: currentData['ticket_change']!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Charts Section
              Text(
                'Análisis de Ventas',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Row(
                  children: [
                    // Sales Chart
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(26)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ventas Diarias',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(child: _SalesChart()),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Category Breakdown
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(13),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withAlpha(26)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ventas por Categoría',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(child: _CategoryChart()),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withAlpha(51),
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
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _SalesChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Simple bar chart representation
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(height: 0.6, label: 'Lun'),
            _Bar(height: 0.8, label: 'Mar'),
            _Bar(height: 0.4, label: 'Mie'),
            _Bar(height: 0.9, label: 'Jue'),
            _Bar(height: 0.7, label: 'Vie'),
            _Bar(height: 1.0, label: 'Sab'),
            _Bar(height: 0.5, label: 'Dom'),
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final String label;

  const _Bar({required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 20,
          height: 100 * height,
          decoration: BoxDecoration(
            color: const Color(0xFF05e265),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}

class _CategoryChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryItem(
          name: 'Electrónicos',
          percentage: 35,
          color: const Color(0xFF05e265),
        ),
        const SizedBox(height: 12),
        _CategoryItem(
          name: 'Ropa',
          percentage: 25,
          color: const Color(0xFF2196F3),
        ),
        const SizedBox(height: 12),
        _CategoryItem(
          name: 'Alimentos',
          percentage: 20,
          color: const Color(0xFFFF9800),
        ),
        const SizedBox(height: 12),
        _CategoryItem(
          name: 'Otros',
          percentage: 20,
          color: const Color(0xFF9C27B0),
        ),
      ],
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String name;
  final double percentage;
  final Color color;

  const _CategoryItem({
    required this.name,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '$percentage%',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(26),
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
