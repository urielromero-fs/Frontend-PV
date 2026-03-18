import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/reports_service.dart'; 


class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _selectedPeriod = 'Este Día';


  Map<String, dynamic> metricData = {};


  @override
  void initState() {
    super.initState();
   
    _loadMetrics(_selectedPeriod); 
  }
  
  Future<void> _loadMetrics(String period) async{


    final Map days = {
      'Este Día': 'day', 
      'Esta Semana': 'week',
      'Este Mes': 'month',
    }; 


    final result = await ReportsService.getReport(period: days[period]);


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


           
      List<Map<String, dynamic>> salesWeekData = [];

      final rawSalesWeek = data['salesWeek'];
      if (rawSalesWeek != null && rawSalesWeek is List) {
        salesWeekData = rawSalesWeek.map<Map<String, dynamic>>((e) {
          final map = e as Map<String, dynamic>? ?? {};
          return {
            'day': map['day']?.toString() ?? '',
            'total': map['total'] ?? 0,
          };
        }).toList();
      }

      Map<String, dynamic> mappedData = {
        'ventas': formatCurrency(actualReport['totalSales']),
        'ordenes': formatNumber(actualReport['ordersCount']),
        'productos': formatNumber(actualReport['productsSold']),
        'ticket': formatCurrency(actualReport['averageTicket']),
        'ventas_change': formatChange(growth['salesGrowth']),
        'ordenes_change': formatChange(growth['ordersGrowth']),
        'products_change': formatChange(growth['productsGrowth'] ?? 0),
        'ticket_change': formatChange(growth['ticketGrowth']),
        'salesWeek': salesWeekData,
        'categoryCount': actualReport['categoryCount'] ?? {},
      };



        setState(() {
          metricData[period] = mappedData;
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


        _loadMetrics(period); 
        
        setState(() {
          _selectedPeriod = period;
        });
        Navigator.pop(context);



      },
    );
  }

  void _exportReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generando y descargando reporte'),
        backgroundColor: const Color(0xFF05e265),
      ),
    );

    // Llamar al servicio
      final result = await ReportsService.downloadSalesExcel();

      // Mostrar mensaje de éxito o error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final currentData = metricData[_selectedPeriod] ?? {} ;

   

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
                      value: currentData['ventas'] ?? '\$0',
                      icon: Icons.trending_up,
                      color: const Color(0xFF05e265),
                      change: currentData['ventas_change'] ?? '0%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Órdenes',
                      value: currentData['ordenes'] ?? '0',
                      icon: Icons.receipt,
                      color: const Color(0xFF2196F3),
                      change: currentData['ordenes_change'] ?? '0%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      title: 'Productos Vendidos',
                      value: currentData['productos'] ?? '0',
                      icon: Icons.inventory,
                      color: const Color(0xFFFF9800),
                      change: currentData['products_change'] ?? '0%',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MetricCard(
                      title: 'Ticket Promedio',
                      value: currentData['ticket'] ?? '\$0',
                      icon: Icons.attach_money,
                      color: const Color(0xFF9C27B0),
                      change: currentData['ticket_change'] ?? '0%',
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
                            
                            Expanded(
                              
                              child: _SalesChart(currentData['salesWeek']  ?? []),
                            ),
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
                            Expanded(child: _CategoryChart( categoryData: currentData['categoryCount'])),
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

// class _SalesChart extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.end,
//       children: [
//         // Simple bar chart representation
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceAround,
//           crossAxisAlignment: CrossAxisAlignment.end,
//           children: [
//             _Bar(height: 0.6, label: 'Lun'),
//             _Bar(height: 0.8, label: 'Mar'),
//             _Bar(height: 0.4, label: 'Mie'),
//             _Bar(height: 0.9, label: 'Jue'),
//             _Bar(height: 0.7, label: 'Vie'),
//             _Bar(height: 1.0, label: 'Sab'),
//             _Bar(height: 0.5, label: 'Dom'),
//           ],
//         ),
//       ],
//     );
//   }
// }



class _SalesChart extends StatelessWidget {
  final List<Map<String, dynamic>> salesWeek;

  const _SalesChart(this.salesWeek);

  @override
  Widget build(BuildContext context) {

   
    if (salesWeek.isEmpty) {
      return Center(
        child: Text(
          'No hay datos',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    // Calculamos el valor máximo para normalizar alturas
    final maxTotal = salesWeek.map((e) => (e['total'] as num).toDouble()).fold<double>(
          0,
          (prev, element) => element > prev ? element : prev,
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: salesWeek.map((e) {
        final double total = (e['total'] as num).toDouble();
        final double heightFactor = maxTotal > 0 ? total / maxTotal : 0;
        return _AnimatedBar(
          heightFactor: heightFactor,
          label: e['day'] ?? '',
          color: const Color(0xFF05e265),
        );
      }).toList(),
    );
  }
}


class _AnimatedBar extends StatelessWidget {
  final double heightFactor;
  final String label;
  final Color color;

  const _AnimatedBar({
    required this.heightFactor,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Animated container para altura
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          width: 20,
          height: 100 * heightFactor,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 8),
        // Label siempre debajo
        Text(
          label,
          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}


class _CategoryChart extends StatelessWidget {
  final Map<String, dynamic>? categoryData;

  const _CategoryChart({this.categoryData});

  @override
  Widget build(BuildContext context) {
    if (categoryData == null || categoryData!.isEmpty) {
      return Center(
        child: Text(
          'No hay datos',
          style: GoogleFonts.poppins(color: Colors.white70),
        ),
      );
    }

    // Convertimos el map en lista de pares y tomamos solo las 4 primeras
    final List<MapEntry<String, dynamic>> topCategories = categoryData!.entries
        .toList()
        .take(4)
        .toList();

    // Calculamos el total para porcentajes
    final total = topCategories.fold<double>(
      0,
      (prev, element) => prev + (element.value is num ? element.value.toDouble() : 0),
    );

    // Colores predefinidos para hasta 4 categorías
    final List<Color> colors = [
      const Color(0xFF05e265),
      const Color(0xFF2196F3),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
    ];

    return Column(
      children: List.generate(topCategories.length, (index) {
        final category = topCategories[index];
        final double rawPercentage =
            total > 0 ? (category.value is num ? category.value.toDouble() : 0) / total * 100 : 0;
        final int percentage = rawPercentage.round(); // Convertimos a entero

        return Column(
          children: [
            _CategoryItem(
              name: category.key,
              percentage: percentage.toDouble(),
              color: colors[index],
            ),
            const SizedBox(height: 12),
          ],
        );
      }),
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

