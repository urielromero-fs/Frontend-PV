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
  List<dynamic> _users = [];
  bool _isLoadingBranches = false;
  bool _isLoadingUsers = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadUsers();
  }

  Future<void> _loadBranches() async {
    setState(() => _isLoadingBranches = true);
    final result = await ReportsService.getBranches();
    if (mounted) {
      final List<dynamic> fetchedBranches = (result['success'] && result['data'] is List) 
          ? result['data'] 
          : [];

      if (fetchedBranches.isNotEmpty) {
        setState(() {
          _branches = fetchedBranches;
          _isLoadingBranches = false;
        });
      } else {
        setState(() {
          _branches = [
            {'name': 'Sucursal Centro'},
            {'name': 'Sucursal Poniente'},
          ];
          _isLoadingBranches = false;
        });
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    final result = await UsersService.getUsers();
    if (mounted) {
      final List<dynamic> fetchedUsers = (result['success'] && result['data'] is List) 
          ? result['data'] 
          : [];

      if (fetchedUsers.isNotEmpty) {
        setState(() {
          _users = fetchedUsers;
          _isLoadingUsers = false;
        });
      } else {
        // Fallback or Dummy data
        setState(() {
          _users = [
            {'_id': 'u1', 'name': 'Uriel Romero', 'email': 'uriel@ejemplo.com', 'role': 'admin', 'sucursal': 'Sucursal Centro'},
            {'_id': 'u2', 'name': 'Carlos Pérez', 'email': 'carlos@ejemplo.com', 'role': 'seller', 'sucursal': 'Sucursal Poniente'},
            {'_id': 'u3', 'name': 'Ana García', 'email': 'ana@ejemplo.com', 'role': 'seller', 'sucursal': 'Sucursal Centro'},
          ];
          _isLoadingUsers = false;
        });
      }
    }
  }

  String _roleLabel(String? role) {
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'seller':
        return 'Cajero';
      case 'master':
        return 'Master';
      default:
        return role ?? 'Sin rol';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'admin':
        return Colors.blueAccent;
      case 'seller':
        return const Color(0xFF05e265);
      case 'master':
        return Colors.deepPurpleAccent;
      default:
        return Colors.grey;
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

    Future<void> submitForm(StateSetter setModalState) async {
      if (isSubmitting) return;
      if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
        setModalState(() => isSubmitting = true);

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
            // Dar un pequeno respiro al backend antes de recargar
            Future.delayed(const Duration(milliseconds: 500), () => _loadUsers());
          } else {
            setModalState(() => isSubmitting = false);
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
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter) {
                  submitForm(setModalState);
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
                          style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Nombre Completo',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedBranch,
                          dropdownColor: Theme.of(context).cardColor,
                          style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Sucursal',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: _branches
                              .map((branch) => DropdownMenuItem(
                                    value: branch['name'].toString(),
                                    child: Text(branch['name'].toString()),
                                  ))
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedBranch = val),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          dropdownColor: Theme.of(context).cardColor,
                          style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Rol',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: ['Administrador', 'Cajero']
                              .map((val) => DropdownMenuItem(
                                  value: val, child: Text(val)))
                              .toList(),
                          onChanged: (val) =>
                              setModalState(() => selectedRole = val!),
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
                    onPressed: isSubmitting
                        ? null
                        : () => submitForm(setModalState),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF05e265)),
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Crear',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showEditUserForm(Map<String, dynamic> user) {
    final nameController =
        TextEditingController(text: user['name'] ?? '');
    final emailController =
        TextEditingController(text: user['email'] ?? '');

    // Map API role to display role
    String currentRole = user['role'] ?? 'seller';
    String selectedRole =
        currentRole == 'admin' ? 'Administrador' : 'Cajero';

    String? selectedBranch = user['sucursal']?.toString();
    // If branch not found in list, fallback to first
    if (_branches.isNotEmpty &&
        !_branches.any((b) => b['name'] == selectedBranch)) {
      selectedBranch = _branches[0]['name'];
    }

    bool isSubmitting = false;

    Future<void> submitEdit(StateSetter setModalState) async {
      if (isSubmitting) return;
      setModalState(() => isSubmitting = true);

      final result = await UsersService.updateUser(
        id: user['_id'] ?? user['id'],
        name: nameController.text,
        email: emailController.text,
        role: selectedRole == 'Administrador' ? 'admin' : 'seller',
        sucursal: selectedBranch,
      );

      if (mounted) {
        if (result['success']) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Usuario actualizado exitosamente'),
              backgroundColor: Color(0xFF05e265),
            ),
          );
          _loadUsers();
        } else {
          setModalState(() => isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: Text(
              'Editar Usuario',
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
                      style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedBranch,
                      dropdownColor: Theme.of(context).cardColor,
                      style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Sucursal',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _branches
                          .map((branch) => DropdownMenuItem(
                                value: branch['name'].toString(),
                                child: Text(branch['name'].toString()),
                              ))
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedBranch = val),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      dropdownColor: Theme.of(context).cardColor,
                      style: GoogleFonts.outfit(
                          color: Theme.of(context).colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: 'Rol',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: ['Administrador', 'Cajero']
                          .map((val) =>
                              DropdownMenuItem(value: val, child: Text(val)))
                          .toList(),
                      onChanged: (val) =>
                          setModalState(() => selectedRole = val!),
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
                onPressed:
                    isSubmitting ? null : () => submitEdit(setModalState),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent),
                child: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Guardar',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  void _showBranchForm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Nueva Sucursal',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Nombre de la Sucursal',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Ubicación / Dirección',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent),
            child:
                const Text('Crear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Panel de Usuarios',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme:
            IconThemeData(color: theme.colorScheme.onSurface),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestión de Personal y Sedes',
              style: GoogleFonts.outfit(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Action card
            SizedBox(
              width: 320,
              child: _PanelCard(
                title: 'Crear Usuario',
                icon: Icons.person_add_rounded,
                color: const Color(0xFF05e265),
                onTap: _showUserForm,
              ),
            ),

            const SizedBox(height: 28),

            // Users list header
            Row(
              children: [
                Text(
                  'Usuarios registrados',
                  style: GoogleFonts.outfit(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05e265).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_users.length} Total',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF05e265),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadUsers,
                  icon: const Icon(Icons.refresh_rounded),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.outfit(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o sucursal...',
                hintStyle: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.4)),
                prefixIcon: Icon(Icons.search_rounded, color: theme.colorScheme.onSurface.withOpacity(0.4)),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _isLoadingUsers
                  ? const Center(child: CircularProgressIndicator())
                  : _buildUserList(theme),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildUserList(ThemeData theme) {
    final filteredUsers = _users.where((user) {
      final name = (user['name'] ?? '').toString().toLowerCase();
      final email = (user['email'] ?? '').toString().toLowerCase();
      final sucursal = (user['sucursal'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          sucursal.contains(query);
    }).toList();

    if (filteredUsers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded,
                size: 48, color: theme.dividerColor),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No hay usuarios registrados'
                  : 'No se encontraron resultados',
              style: GoogleFonts.outfit(
                  color: theme.colorScheme.onSurface.withOpacity(0.5)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredUsers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final role = user['role']?.toString();
        final name = user['name']?.toString() ?? 'Sin nombre';
        final email = user['email']?.toString() ?? '';
        final sucursal = user['sucursal']?.toString() ?? '—';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: _roleColor(role).withOpacity(0.15),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.outfit(
                    color: _roleColor(role),
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      email,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ),

              // Sucursal chip
              _InfoChip(
                label: sucursal,
                icon: Icons.store_rounded,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),

              // Role chip
              _InfoChip(
                label: _roleLabel(role),
                icon: Icons.badge_rounded,
                color: _roleColor(role),
              ),
              const SizedBox(width: 8),

              // Edit button
              IconButton(
                onPressed: () => _showEditUserForm(user),
                icon: const Icon(Icons.edit_rounded, size: 20),
                color: Colors.blueAccent,
                tooltip: 'Editar',
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Chips ───────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _InfoChip(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Panel Card ───────────────────────────────────────────────────────────────

class _PanelCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PanelCard(
      {required this.title,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color:
                    Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                    fontSize: 15, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
