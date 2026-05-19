import 'package:flutter/material.dart';
import 'package:pv26/core/utils/role_utils.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/users_service.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/attendance_service.dart'; 


class UsersScreen extends StatefulWidget {
  final bool showAppBar;
  const UsersScreen({super.key, this.showAppBar = true});

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


    Map<String, dynamic> _onboarding = {
      'isCompleted': false,
      'stepsCompleted': {
        'users': false,
      },
    };

    String? branchId; 

    

  List<dynamic> _attendanceHistory = [];
  bool _loadingHistory = false;



  @override
  void initState() {

    super.initState();

    _loadOnboarding().then((_) {
      _initOnboarding(); 
    });

    _filteredUsers = users;
    _searchController.addListener(_onSearchChanged);
    _loadUsers(); 

    _initBranch(); 

  }


    Future<void> _initBranch() async {
 
      final prefs = await SharedPreferences.getInstance();
    
      branchId = prefs.getString('user_current_location');;
        
   
  }


  Future<void> _initOnboarding() async {

    if(_onboarding['isCompleted'] == true) return;

    if(_onboarding['stepsCompleted']['users'] == true) return; 

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 600), () {
        ShowcaseView.get().startShowCase([   
          _addUserKey,
          _optionsUserKey
          
        ]);
      });
    });

     await _markUsersOnboardingCompleted(); 
  }

  Future<void> _loadOnboarding() async {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('user_onboarding');
      
      if (jsonStr != null) {
        setState(() {
          _onboarding = jsonDecode(jsonStr);
          
        });
      }
  }

  Future<void> _markUsersOnboardingCompleted() async {

    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _onboarding['stepsCompleted']['users'] = true;
    });

    await prefs.setString('user_onboarding', jsonEncode(_onboarding));

    final result = await UsersService.updateOnboardingStep(step: 'users');

    if (!result['success']) {
      print('Error al actualizar onboarding: ${result['message']}');
    }

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
        users = data.where((user) => user['role'] != 'creator').map((user) => {
          'id': user['id'],
          'name': user['name'],
          'email': user['email'],
          'sucursal': user['sucursal'] ?? 'Sucursal Principal', 
          'role': RoleUtils.getRoleLabel(user['role']),

          'status': user['state'] == 'active' ? 'Activo' : 'Inactivo',
          'joinDate':  user['createdAt'] != null
              ? DateFormat('dd-MM-yyyy').format(DateTime.parse(user['createdAt']))
              : 'Desconocida',
          'isCheckedIn': user['hasCheckIn'] ?? false, 

          
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
    final sucursalController = TextEditingController(
      text: isEditing ? user['sucursal'] : '',
    );
    String selectedRole = RoleUtils.getRoleLabel(user?['role'] ?? 'seller');

    bool isSubmitting = false;

    Future<void> submitForm() async {
      if (isSubmitting) return;
      if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
        isSubmitting = true;
        Map<String, dynamic> result;

        if (isEditing) {
          result = await UsersService.updateUser(
            id: user['id'],
            name: nameController.text,
            email: emailController.text,
            role: selectedRole == 'Administrador' ? 'admin' : (selectedRole == 'Creador' ? 'creator' : 'seller'),
            currentLocation: sucursalController.text,
          );
        } else {
          result = await UsersService.createUser(
            name: nameController.text,
            email: emailController.text,
            role: selectedRole == 'Administrador' ? 'admin' : (selectedRole == 'Creador' ? 'creator' : 'seller'),
            currentLocation: sucursalController.text,
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
                      TextField(
                        controller: sucursalController,
                        onSubmitted: (_) => submitForm(),
                        style: GoogleFonts.poppins(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Sucursal',
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
  
  

void _handleCheckIn(String user) {

    final parentContext = context; 

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Center(
        child: Text(
          'Registrar Entrada',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Se marcará su entrada:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: const Color(0xFF05e265),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '¿Desea continuar?',
            style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final now = DateTime.now();

                final result = await AttendanceService.checkIn(
                  locationId: branchId!,
                  checkInDate: now.toIso8601String(), 
                  userId: user
                );



                if (!parentContext.mounted) return;


                if (result['success']) {  
                  _loadUsers();

                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Entrada registrada'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05e265),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Aceptar',
                style: GoogleFonts.poppins(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    ),
  );
}


void _handleCheckOut(String user) {

  final parentContext = context;

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Center(
        child: Text(
          'Registrar Salida',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Se marcará su salida:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          Text(
            DateFormat('HH:mm').format(DateTime.now()),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 32,
              color: Colors.orange,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '¿Desea continuar?',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [

            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () async {

                Navigator.pop(dialogContext);

                final now = DateTime.now();

                final result = await AttendanceService.checkOut(
                  locationId: branchId!,
                  checkOutDate: now.toIso8601String(),
                  userId: user,
                );

                if (!parentContext.mounted) return;
            

                if (result['success']) {

                  _loadUsers();

                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                      content: Text('Salida registrada'),
                      backgroundColor: Colors.orange,
                    ),
                  );

                } else {

                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(result['message']),
                      backgroundColor: Colors.red,
                    ),
                  );

                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Aceptar',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),
      ],
    ),
  );
}




Future<void> _loadAttendanceHistory(String userId) async {
  setState(() {
    _loadingHistory = true;
  });

  try {
    final result = await AttendanceService.getLast10AttendanceByUser(
      userId: userId,
    );

    setState(() {
      _attendanceHistory = (result['data'] ?? []) as List<dynamic>;
      _loadingHistory = false;
    });
  } catch (e) {
    setState(() {
      _attendanceHistory = [];
      _loadingHistory = false;
    });
  }
}


void _showAttendanceHistory(String userId) async {
  await _loadAttendanceHistory(userId);

  showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'Historial de Asistencia',
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 600,
        height: 400,
        child: _loadingHistory
            ? const Center(child: CircularProgressIndicator())
            : _attendanceHistory.isEmpty
                ? Center(
                    child: Text(
                      'Sin registros',
                      style: GoogleFonts.poppins(),
                    ),
                  )
                : SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Text(
                            'Fecha',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Entrada',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Salida',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      rows: _attendanceHistory.map((record) {
                        final checkIn = record['checkIn'] != null
                            ? DateTime.parse(record['checkIn'])
                            : null;

                        final checkOut = record['checkOut'] != null
                            ? DateTime.parse(record['checkOut'])
                            : null;

                        return DataRow(
                          cells: [
                            DataCell(
                              Text(
                                checkIn != null
                                    ? DateFormat('dd/MM/yyyy').format(checkIn)
                                    : '--',
                              ),
                            ),
                            DataCell(
                              Text(
                                checkIn != null
                                    ? DateFormat('HH:mm').format(checkIn)
                                    : '--',
                              ),
                            ),
                            DataCell(
                              Text(
                                checkOut != null
                                    ? DateFormat('HH:mm').format(checkOut)
                                    : '--',
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text('Cerrar', style: GoogleFonts.poppins()),
        ),
      ],
    ),
  );
}




  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      appBar: widget.showAppBar ? AppBar(
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
        leading: isMobile ? IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ) : null,
      ) : null,
      /* Removed FloatingActionButton as requested and moved it to the top */
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.light
                        ? Theme.of(context).dividerColor
                        : Theme.of(context).dividerColor.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Theme.of(context).dividerColor
                          : Theme.of(context).dividerColor.withOpacity(0.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.light ? 0.04 : 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Encabezado de la tabla (solo en escritorio)
                      if (!isMobile) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).brightness == Brightness.light
                                ? Theme.of(context).dividerColor.withOpacity(0.15)
                                : Theme.of(context).dividerColor.withOpacity(0.03),
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
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Rol / Sucursal',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Registro',
                                  style: GoogleFonts.poppins(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
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
                                    'Asistencia',
                                    style: GoogleFonts.poppins(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child:
                                  
                                  Showcase(
                                      key: _optionsUserKey,
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
                                          Text(
                                            'Acciones',
                                            style: GoogleFonts.poppins(
                                              color: Theme.of(context).colorScheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                  //final GlobalKey? actionMenuKey = index == 0 ? _optionsUserKey : null;

                                  return _UserRow(
                                    name: user['name'],
                                    email: user['email'],
                                    role: user['role'],
                                    sucursal: user['sucursal'],
                                    joinDate: user['joinDate'],
                                    status: user['status'] ?? 'Activo',
                                    isMobile: isMobile,
                                    isCheckedIn: user['isCheckedIn'] ?? false,
                                    onEdit: () => _showUserForm(user),
                                    onDelete: () => _deleteUser(user['id']),
                                    onSendPassword: () => _sendPassword(user['email']),
                                    onCheckIn: () => _handleCheckIn(user['id']),
                                    onCheckOut: () => _handleCheckOut(user['id']),
                                    onShowHistory: () => _showAttendanceHistory(user['id']),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? color.withOpacity(0.15)
            : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? color.withOpacity(0.4)
              : color.withOpacity(0.18),
          width: Theme.of(context).brightness == Brightness.dark ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    fontSize: 10,
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
  final String sucursal;
  final String joinDate;
  final String status;
  final bool isMobile;
  final bool isCheckedIn;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSendPassword;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;
  final VoidCallback onShowHistory;

  const _UserRow({
    required this.name,
    required this.email,
    required this.role,
    required this.sucursal,
    required this.joinDate,
    required this.status,
    required this.isMobile,
    required this.isCheckedIn,
    required this.onEdit,
    required this.onDelete,
    required this.onSendPassword,
    required this.onCheckIn,
    required this.onCheckOut,
    required this.onShowHistory,
  });

  @override
  Widget build(BuildContext context) {
    final bool isInactive = status == 'Inactivo';
    final Color statusColor = isInactive ? const Color(0xFFFF5252) : const Color(0xFF05e265);
    
    final actionsMenu = PopupMenuButton<String>(
      color: Theme.of(context).cardColor,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) {
        if (value == 'edit' || value == 'enable') onEdit();
        if (value == 'delete') onDelete();
        if (value == 'password') onSendPassword();
        if (value == 'history') onShowHistory();
      },
      itemBuilder: (context) => isInactive
        ? [
            PopupMenuItem(
              value: 'enable',
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF05e265), size: 18),
                  const SizedBox(width: 12),
                  Text('Habilitar', style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 12),
                  Text('Eliminar', style: GoogleFonts.poppins(fontSize: 13, color: Colors.redAccent)),
                ],
              ),
            ),
          ]
        : [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit_rounded, color: Color(0xFF05e265), size: 18),
                  const SizedBox(width: 12),
                  Text('Editar', style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'password',
              child: Row(
                children: [
                  const Icon(Icons.key_rounded, color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 12),
                  Text('Enviar contraseña', style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'history',
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, color: Colors.orangeAccent, size: 18),
                  const SizedBox(width: 12),
                  Text('Historial de Asistencia', style: GoogleFonts.poppins(fontSize: 13)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                  const SizedBox(width: 12),
                  Text('Eliminar', style: GoogleFonts.poppins(fontSize: 13, color: Colors.redAccent)),
                ],
              ),
            ),
          ],
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF05e265).withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.more_vert, color: Color(0xFF05e265), size: 20),
      ),
    );

    if (isMobile) {
      return Opacity(
        opacity: isInactive ? 0.6 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFF05e265).withOpacity(0.1),
                    child: Text(name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Color(0xFF05e265))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                        Text(email, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  actionsMenu,
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatusBadge(status, statusColor),
                  if (isInactive)
                    ElevatedButton(
                      onPressed: null,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      child: const Text('Inactivo', style: TextStyle(color: Colors.white)),
                    )
                  else if (isCheckedIn)
                    ElevatedButton(
                      onPressed: onCheckOut,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                      child: const Text('Salida', style: TextStyle(color: Colors.white)),
                    )
                  else
                    ElevatedButton(
                      onPressed: onCheckIn,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05e265)),
                      child: const Text('Entrada', style: TextStyle(color: Colors.black)),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).dividerColor
                  : Theme.of(context).dividerColor.withOpacity(0.05),
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(name, style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
            Expanded(child: Text(role, style: GoogleFonts.poppins())),
            Expanded(child: Text(joinDate, style: GoogleFonts.poppins())),
            Expanded(child: Center(child: _buildStatusBadge(status, statusColor))),
            Expanded(
              child: Center(
                child: isInactive
                  ? ElevatedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.block, size: 14),
                      label: const Text('Inactivo', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey, foregroundColor: Colors.white),
                    )
                  : (isCheckedIn
                      ? ElevatedButton.icon(
                          onPressed: onCheckOut,
                          icon: const Icon(Icons.exit_to_app, size: 14),
                          label: const Text('Salida', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                        )
                      : ElevatedButton.icon(
                          onPressed: onCheckIn,
                          icon: const Icon(Icons.login, size: 14),
                          label: const Text('Entrada', style: TextStyle(fontSize: 11)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05e265), foregroundColor: Colors.black),
                        )),
              ),
            ),
            Expanded(child: Center(child: actionsMenu)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTag(BuildContext context, IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}





