import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/users_service.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {


  List<Map<String, dynamic>> users = [];
  bool isLoading = true;
  List<Map<String, dynamic>> _filteredUsers = [];
  final TextEditingController _searchController = TextEditingController();

  //Onboarding  
  final GlobalKey _addUserKey = GlobalKey(); 
  final GlobalKey _optionsUserKey = GlobalKey(); 
  
  static const String _usersOnboardingKey = 'onboarding_users';

  Future<bool> _shouldShowOnboarding() async {
      final prefs = await SharedPreferences.getInstance();
      return !(prefs.getBool(_usersOnboardingKey) ?? false);
    }

  Future<void> _setOnboardingShown() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_usersOnboardingKey, true);
    }


  @override
  void initState() {

    //     //Onboarding
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   Future.delayed(const Duration(milliseconds: 600), () {
    //     ShowcaseView.get().startShowCase([
    //       _addUserKey,
    //       _optionsUserKey
          
    //     ]);
    //   });
    // });


    super.initState();
    _filteredUsers = users;
    _searchController.addListener(_onSearchChanged);
    _loadUsers(); 

      // Onboarding
    _initOnboarding();

  }

  Future<void> _initOnboarding() async {
    final shouldShow = await _shouldShowOnboarding();
    if (!shouldShow) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        ShowcaseView.get().startShowCase([   
          _addUserKey,
          _optionsUserKey
          
        ]);
      });
    });

    await _setOnboardingShown();
  }


  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }


  Future<void> _loadUsers() async {
    final result = await UsersService.getUsers();

    if (result['success']) {
      
      final List data = result['data']['users']; 

  
      setState(() {
        users = data.map((user) => {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'role': user['role'] == 'admin' 
          ? 'Administrador' 
          : user['role'] == 'seller' 
                ? 'Cajero' 
                : 'Vendedor',

          'status': user['state'] == 'active' ? 'Activo' : 'Inactivo',
          'joinDate':  user['createdAt'] != null
              ? DateFormat('dd-MM-yyyy').format(DateTime.parse(user['createdAt']))
              : 'Desconocida',
        }).toList();

        _filteredUsers = users;
        isLoading = false;
      });

    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al cargar usuarios'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
     

  }

  Future<void> _sendPassword(String email) async {

      final result = await UsersService.sendNewPassword(email: email);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contraseña enviada a $email'),
            backgroundColor: const Color(0xFF05e265),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Error al enviar contraseña'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }

  void _onSearchChanged() {
    setState(() {
      _filteredUsers = users.where((user) {
        final name = user['name'].toString().toLowerCase();
        final email = user['email'].toString().toLowerCase();
        final query = _searchController.text.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    });
  }

  void _showUserForm([Map<String, dynamic>? user]) {


    final bool isEditing = user != null;
    final nameController = TextEditingController(
      text: isEditing ? user['name'] : '',
    );
    final emailController = TextEditingController(
      text: isEditing ? user['email'] : '',
    );
    String selectedRole = isEditing ? user['role'] : 'Cajero';

    bool isSubmitting = false;

    Future<void> submitForm() async {
      if (isSubmitting) return;
      if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
        isSubmitting = true;
        Map<String, dynamic> result;

        if (isEditing) {
          result = await UsersService.updateUser(
            id: user!['id'],
            name: nameController.text,
            email: emailController.text,
            role: selectedRole == 'Administrador' ? 'admin' : 'seller',
          );
        } else {
          result = await UsersService.createUser(
            name: nameController.text,
            email: emailController.text,
            role: selectedRole == 'Administrador' ? 'admin' : 'seller',
          );
        }

        if (result['success']) {
          await _loadUsers();
          if (mounted) Navigator.pop(context);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isEditing
                    ? 'Usuario actualizado exitosamente'
                    : 'Usuario creado exitosamente'),
                backgroundColor: const Color(0xFF05e265),
              ),
            );
          }
        } else {
          isSubmitting = false;
          if (mounted) {
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
                  isEditing ? 'Editar Usuario' : 'Nuevo Usuario',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 500, // Matching the inventory form width
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        autofocus: true,
                        controller: nameController,
                        onSubmitted: (_) => submitForm(),
                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Nombre Completo',
                          labelStyle: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF05e265),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: emailController,
                        onSubmitted: (_) => submitForm(),
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          labelStyle: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF05e265),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        dropdownColor: Theme.of(context).cardColor,
                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Rol',
                          labelStyle: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF05e265),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Administrador', 'Cajero'].map((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setModalState(() {
                            selectedRole = newValue!;
                          });
                        },
                      ),
                    ],
                  ),
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
                  onPressed: submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05e265),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    isEditing ? 'Guardar' : 'Crear',
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
      },
    );
  }

  void _deleteUser(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Eliminar Usuario',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar este usuario?',
          style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
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
                final result = await UsersService.inactivateUser(id: id);

                if(result['success']){

                
                  await _loadUsers();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: const Color.fromARGB(255, 30, 233, 128),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                }
              },
            child: Text(
              'Eliminar',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Usuarios',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          
                      //add user  button
                  Showcase(
                          key: _addUserKey,
                          description: 'Toca para agregar un usuario nuevo. Las credenciales del usuario le llegaran al correo que proporcione.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                                ElevatedButton.icon(
                                  onPressed: () => _showUserForm(),
                                  icon: const Icon(Icons.add, size: 18, color: Colors.black),
                                  label: Text(
                                    'Agregar usuario',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF05e265),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),


                        ) 

                    

         // const SizedBox(width: 16),
        ],
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      /* Removed FloatingActionButton as requested and moved it to the top */
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: Color(0xFF05e265),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar usuarios...',
                          hintStyle: GoogleFonts.poppins(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // User Stats
              Row(
                children: [
                  Expanded(
                    child: _UserStatCard(
                      title: 'Total Usuarios',
                      value: users.length.toString(),
                      icon: Icons.people,
                      color: const Color(0xFF05e265),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _UserStatCard(
                      title: 'Activos Hoy',
                      value: users.where((u) => u['status'] == 'Activo').length.toString(),
                      icon: Icons.person_pin,
                      color: const Color(0xFF2196F3),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _UserStatCard(
                      title: 'Inactivos',
                      value: users.where((u) => u['status'] == 'Inactivo').length.toString(),
                      icon: Icons.person_off,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Users List
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      // Encabezado de la tabla (solo en escritorio)
                      if (!isMobile) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).dividerColor.withOpacity(0.03),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(12),
                              topRight: Radius.circular(12),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'Usuario',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Rol',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Registro',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Estado',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: Text(
                                    'Acciones',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(color: Theme.of(context).dividerColor.withOpacity(0.1), height: 1),
                      ],
                      // Lista de usuarios
                      Expanded(
                        child: _filteredUsers.isEmpty
                            ? Center(
                                child: Text(
                                  'No hay usuarios registrados',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = _filteredUsers[index];


                                  // Solo el primer producto tendrá showcase (por ejemplo)
                                  final GlobalKey? actionMenuKey = index == 0 ? _optionsUserKey : null;


                                  return _UserRow(
                                    name: user['name'],
                                    email: user['email'],
                                    role: user['role'],
                                    joinDate: user['joinDate'],
                                    status: user['status'] ?? 'Activo',
                                    isMobile: isMobile,
                                    onEdit: () => _showUserForm(user),
                                    onDelete: () => _deleteUser(user['id']),
                                    onSendPassword: () => _sendPassword(user['email']),
                                    // SHOWCASE solo para este producto
                                  
                                    actionMenuKey: actionMenuKey,
                                  );
                                },
                              ),
                      ),
                    ],
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

class _UserStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _UserStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String joinDate;
  final String status;
  final bool isMobile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSendPassword; 

  // SHOWCASE
  final GlobalKey? actionMenuKey;
  

  const _UserRow({
    required this.name,
    required this.email,
    required this.role,
    required this.joinDate,
    required this.status,
    required this.isMobile,
    required this.onEdit,
    required this.onDelete,
    required this.onSendPassword,
    this.actionMenuKey,
  });






  @override
  Widget build(BuildContext context) {
    final Color statusColor = status == 'Inactivo' ? const Color(0xFFE91E63) : const Color(0xFF05e265);
    final bool isInactive = status == 'Inactivo';

  
    Widget actionButton = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFF05e265).withAlpha(26),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF05e265).withAlpha(51),
            width: 1,
          ),
        ),
        child: const Icon(Icons.more_vert, color: Color(0xFF05e265), size: 20),
      );

    if(actionMenuKey != null){
      actionButton = Showcase(
                          key: actionMenuKey!,
                          description: 'Toca para editar, eliminar o enviarle una nueva contraseña al usuario.',
                          tooltipPadding: const EdgeInsets.all(12),
                          tooltipActions: [
                                    
                                    TooltipActionButton(
                                      type: TooltipDefaultActionType.next,
                                      backgroundColor: const Color.fromARGB(255, 53, 237, 59),
                                      textStyle: TextStyle(color: Colors.white),
                                      name: 'Siguiente',
                                     
                                    )
                                  ],
                          tooltipActionConfig: TooltipActionConfig(
                                alignment: MainAxisAlignment.center,
                              ),
                          child:  
                               
                          actionButton
                        ); 



    }

    final actionsMenu = PopupMenuButton<String>(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (String value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        } else if (value == 'send_password') {
          onSendPassword();
        }
      },
      itemBuilder: (BuildContext context) => [
        PopupMenuItem<String>(
          value: 'send_password',
          child: Row(
            children: [
              const Icon(Icons.send_rounded, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 12),
              Text(
                'Enviar contraseña',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'edit',
          child: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF05e265), size: 20),
              const SizedBox(width: 12),
              Text(
                'Editar',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, color: Color(0xFFE91E63), size: 20),
              const SizedBox(width: 12),
              Text(
                'Eliminar',
                style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
      child: 
        actionButton


    );

    final Widget actionsMenuDisabled = Opacity(
      opacity: isInactive ? 0.4 : 1,
      child: IgnorePointer(
        ignoring: isInactive,
        child: actionsMenu,
      ),
    );



    if (isMobile) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF05e265).withOpacity(0.2),
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF05e265),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rol: $role',
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                 actionsMenuDisabled,
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registro: $joinDate',
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.poppins(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF05e265).withOpacity(0.2),
                  radius: 16,
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF05e265),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        email,
                        style: GoogleFonts.poppins(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              role,
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              joinDate,
              style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
            ),
          ),
          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: Center(child: actionsMenuDisabled)),
        ],
      ),
    );
  }
}





