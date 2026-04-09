import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pv26/features/users/services/users_service.dart';
import 'package:pv26/features/reports/services/reports_service.dart';

class UsersPanelScreen extends StatefulWidget {
  const UsersPanelScreen({super.key});

  @override
  State<UsersPanelScreen> createState() => _UsersPanelScreenState();
}

class _UsersPanelScreenState extends State<UsersPanelScreen> {
  List<dynamic> _branches = [];
  bool _isLoadingBranches = false;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    final result = await ReportsService.getBranches();
    if (mounted && result['success']) {
      setState(() {
        _branches = result['data'];
      });
    }
  }

  void _showUserForm() {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    String? selectedBranch;
    if (_branches.isNotEmpty) {
      selectedBranch = _branches[0]['name'];
    }
    String selectedRole = 'Cajero';
    bool isSubmitting = false;

    Future<void> submitForm() async {
      if (isSubmitting) return;
      if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
        setState(() => isSubmitting = true);
        
        final result = await UsersService.createUser(
          name: nameController.text,
          email: emailController.text,
          role: selectedRole == 'Administrador' ? 'admin' : 'seller',
          sucursal: selectedBranch ?? 'Principal',
        );

        if (mounted) {
          if (result['success']) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Usuario creado exitosamente'),
                backgroundColor: Color(0xFF05e265),
              ),
            );
          } else {
            setState(() => isSubmitting = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message']),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Focus(
              autofocus: false,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
                  submitForm();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: AlertDialog(
                backgroundColor: Theme.of(context).cardColor,
                title: Text(
                  'Nuevo Usuario',
                  style: GoogleFonts.outfit(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          autofocus: true,
                          controller: nameController,
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedBranch,
                          dropdownColor: Theme.of(context).cardColor,
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Sucursal',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _branches.map((branch) => DropdownMenuItem(
                            value: branch['name'].toString(),
                            child: Text(branch['name'].toString()),
                          )).toList(),
                          onChanged: (val) => setModalState(() => selectedBranch = val),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          dropdownColor: Theme.of(context).cardColor,
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['Administrador', 'Cajero'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                          onChanged: (val) => setModalState(() => selectedRole = val!),
                        ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: submitForm,
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05e265)),
                    child: const Text('Crear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showBranchForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Nueva Sucursal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Nombre de la Sucursal',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
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
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('Crear', style: TextStyle(color: Colors.white)),
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
        title: Text('Panel de Usuarios P', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Personal y Sedes',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _PanelCard(
                    title: 'Crear Usuario',
                    icon: Icons.person_add_rounded,
                    color: const Color(0xFF05e265),
                    onTap: _showUserForm,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PanelCard(
                    title: 'Crear Sucursal',
                    icon: Icons.add_business_rounded,
                    color: Colors.blueAccent,
                    onTap: _showBranchForm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _PanelCard({required this.title, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
