import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pv26/features/auth/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';


class CompaniesScreen extends StatefulWidget {
  final bool showAppBar;
  const CompaniesScreen({super.key, this.showAppBar = true});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  XFile? selectedLogo;
  Uint8List? logoBytes;

  final picker = ImagePicker();
  bool _globalLoading = false;
  // Dummy data for companies and branches
  final List<Map<String, dynamic>> _companies = [
    {
      'id': '1',
      'name': 'Empresa A',
      'celular': '5512345678',
      'numero': '101',
      'correo': 'contacto@empresaa.com',
      'isExpanded': false,
      'branches': [
        {
          'id': 'b1',
          'name': 'Sucursal Centro',
          'correo': 'centro@empresaa.com',
          'numero': '001',
          'cashiers': [
            {
              'id': 'c1',
              'name': 'Juan Pérez',
              'correo': 'juan@empresaa.com',
              'numero': '5551112233',
            }
          ],
        },
      ]
    },
    {
      'id': '2',
      'name': 'Empresa B',
      'celular': '5598765432',
      'numero': '102',
      'correo': 'info@empresab.com',
      'isExpanded': false,
      'branches': [],
    },
  ];
  
  bool isSubmitting = false;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  void _setLoading(bool value) {
    if (!mounted) return;
    setState(() {
      _globalLoading = value;
    });
  }

  Future<void> _createCompany({
    required GlobalKey<FormState> formKey,
    required TextEditingController nombreController,
    required TextEditingController celularController,
    required TextEditingController correoController,
    //required Function(void Function()) setModalState,
    XFile? selectedLogo,
  }) async {
    if (!formKey.currentState!.validate()) return;

    _setLoading(true);
    final response = await AuthService.registerCompany(
      name: nombreController.text.trim(),
      email: correoController.text.trim(),
      phone: celularController.text.trim(),
      logo: selectedLogo,
    );

    _setLoading(false);

    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];

      setState(() {
        _companies.add({
          'id': data['user']?['_id']?.toString() ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          'name': data['user']?['name'] ?? nombreController.text,
          'celular': data['user']?['phone'] ?? celularController.text,
          'correo': data['user']?['email'] ?? correoController.text,
          'logoUrl': data['logoUrl'], // 👈 IMPORTANTE
          'isExpanded': false,
          'branches': [],
        });
      });

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: const Color(0xFF05e265),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  Future<void> _pickLogo(
      StateSetter setModalState,
    ) async {

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (pickedFile != null) {

        final bytes = await pickedFile.readAsBytes();

        // Validar PNG
        if (!pickedFile.name.toLowerCase().endsWith('.png')) {

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Solo se permiten imágenes PNG'),
              backgroundColor: Colors.redAccent,
            ),
          );

          return;
        }

        // Validar dimensiones
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        if (image.width > 500 || image.height > 500) {

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('La imagen debe ser máximo 500x500 px'),
              backgroundColor: Colors.redAccent,
            ),
          );

          return;
        }


         

        setModalState(() {
          selectedLogo = pickedFile;
          logoBytes = bytes;
        });
      }
    }

  void _showCompanyForm() {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final celularController = TextEditingController();
    final correoController = TextEditingController();
   

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                'Nueva Compañía',
                style: GoogleFonts.outfit(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nombreController,
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Nombre de la Compañía',
                            prefixIcon: const Icon(Icons.business),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: celularController,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Celular',
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: correoController,
                          keyboardType: TextInputType.emailAddress,
                          style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                          decoration: InputDecoration(
                            labelText: 'Correo Electrónico',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (value) {
                            if (value!.isEmpty) return 'Campo requerido';
                            if (!value.contains('@')) return 'Correo inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),



                      // Row(
                      //   children: [
                      //     AnimatedSwitcher(
                      //       duration: const Duration(milliseconds: 200),
                      //       child: logoBytes != null
                      //           ? ClipRRect(
                      //               borderRadius: BorderRadius.circular(8),
                      //               child: Image.memory(
                      //                 logoBytes!,
                      //                 key: ValueKey(logoBytes), // importante para animación correcta
                      //                 width: 50,
                      //                 height: 50,
                      //                 fit: BoxFit.cover,
                      //               ),
                      //             )
                      //           : const Icon(
                      //               Icons.image,
                      //               key: ValueKey('placeholder'),
                      //               size: 50,
                      //               color: Colors.grey,
                      //             ),
                      //     ),

                      //     const SizedBox(width: 16),

                      //     Expanded(
                      //       child: ElevatedButton.icon(
                      //         onPressed: () => _pickLogo(setModalState),
                      //         icon: const Icon(Icons.upload_file),
                      //         label: const Text('Seleccionar Logotipo'),
                      //       ),
                      //     ),

                      //     const SizedBox(width: 8),

                      //     if (logoBytes != null)
                      //       const Icon(Icons.check_circle, color: Color(0xFF05e265)),
                      //   ],
                      // )
                      

                        Row(
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: logoBytes != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        logoBytes!,
                                        key: ValueKey(logoBytes),
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.image,
                                      key: ValueKey('placeholder'),
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                            ),

                            const SizedBox(width: 16),

                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _pickLogo(setModalState),
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Seleccionar Logotipo'),
                              ),
                            ),

                            const SizedBox(width: 8),

                            if (logoBytes != null) ...[
                              IconButton(
                                tooltip: 'Eliminar logo',
                                onPressed: () {
                                  setModalState(() {
                                    logoBytes = null;
                                    selectedLogo = null;
                                  });
                                },
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                              ),

                              const Icon(Icons.check_circle, color: Color(0xFF05e265)),
                            ],
                          ],
)
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () => _createCompany(
                        formKey: formKey,
                        nombreController: nombreController,
                        celularController: celularController,
                        selectedLogo: selectedLogo,
                        correoController: correoController,
                        //setModalState: setModalState,
                      ),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05e265)),
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Crear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }




  void _showBranchForm(Map<String, dynamic> company) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    final celularController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void submitForm() {
              if (formKey.currentState!.validate()) {
                setModalState(() => isSubmitting = true);
                
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      final branches = company['branches'] as List<dynamic>;
                      branches.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nombreController.text,
                        'correo': correoController.text,
                        'cashiers': [],
                      });
                      company['isExpanded'] = true; // Expand to show the new branch
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Sucursal creada en ${company['name']}'),
                        backgroundColor: Colors.blueAccent,
                      ),
                    );
                  }
                });
              }
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                'Nueva Sucursal - ${company['name']}',
                style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Nombre de la Sucursal',
                          prefixIcon: const Icon(Icons.store),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: celularController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Teléfono',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Crear Sucursal', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCashierForm(Map<String, dynamic> company, Map<String, dynamic> branch) {
    final formKey = GlobalKey<FormState>();
    final nombreController = TextEditingController();
    final correoController = TextEditingController();
    final numeroController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void submitForm() {
              if (formKey.currentState!.validate()) {
                setModalState(() => isSubmitting = true);
                
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted) {
                    setState(() {
                      final cashiers = branch['cashiers'] as List<dynamic>;
                      cashiers.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'name': nombreController.text,
                        'correo': correoController.text,
                        'numero': numeroController.text,
                      });
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Cajero creado en ${branch['name']}'),
                        backgroundColor: const Color(0xFF05e265),
                      ),
                    );
                    
                    // Opcionalmente abrir la lista de cajeros tras crear
                    _showCashiersList(company, branch);
                  }
                });
              }
            }

            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Text(
                'Nuevo Cajero - ${branch['name']}',
                style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: 400,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nombreController,
                        style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Nombre del Cajero',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: correoController,
                        keyboardType: TextInputType.emailAddress,
                        style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Correo Electrónico',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: numeroController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          labelText: 'Número / Teléfono',
                          prefixIcon: const Icon(Icons.numbers),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submitForm,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF05e265)),
                  child: isSubmitting
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Crear Cajero', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCashiersList(Map<String, dynamic> company, Map<String, dynamic> branch) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cashiers = branch['cashiers'] as List<dynamic>? ?? [];
            return AlertDialog(
              backgroundColor: Theme.of(context).cardColor,
              title: Row(
                children: [
                  const Icon(Icons.people_alt, color: Color(0xFF05e265)),
                  const SizedBox(width: 8),
                  Text(
                    'Cajeros - ${branch['name']}',
                    style: GoogleFonts.outfit(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: cashiers.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'No hay cajeros registrados en esta sucursal.',
                          style: GoogleFonts.outfit(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: cashiers.length,
                          itemBuilder: (context, index) {
                            final cashier = cashiers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              color: Theme.of(context).scaffoldBackgroundColor,
                              child: ListTile(
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF05e265),
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                                title: Text(cashier['name'] ?? '', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  '${cashier['correo']}\nCel: ${cashier['numero']}',
                                  style: GoogleFonts.outfit(fontSize: 12),
                                ),
                                trailing: PopupMenuButton<String>(
                                  icon: const Icon(Icons.more_vert),
                                  onSelected: (value) {
                                    if (value == 'edit') {
                                      // TODO: Implement edit
                                    } else if (value == 'delete') {
                                      setModalState(() {
                                        setState(() {
                                          cashiers.removeAt(index);
                                        });
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Cajero eliminado'), backgroundColor: Colors.red),
                                      );
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 20),
                                          SizedBox(width: 8),
                                          Text('Editar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    final filteredCompanies = _companies.where((company) {
      final name = (company['name'] ?? '').toString().toLowerCase();
      final correo = (company['correo'] ?? '').toString().toLowerCase();
      final celular = (company['celular'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || correo.contains(query) || celular.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
     
      appBar: widget.showAppBar ? AppBar(
        title: Text(
          'Compañías',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: theme.cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton.icon(
              onPressed: _showCompanyForm,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(
                'Crear Compañía',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF05e265),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ) : null,


      body: 
      
      Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


             Row(
              children: [
                Text(
                  'Compañías',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),


  

              
            Row(
              children: [
                Text(
                  'Compañías registradas',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(width: 12),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF05e265).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${filteredCompanies.length} Total',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF05e265),
                    ),
                  ),
                ),

                const Spacer(),

                ElevatedButton.icon(
                  onPressed: _showCompanyForm,
                  icon: const Icon(Icons.add, size: 18, color: Colors.white),
                  label: Text(
                    'Crear Compañía',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF05e265),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),


            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: GoogleFonts.outfit(color: theme.colorScheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre, correo o celular...',
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
            Expanded(
              child: filteredCompanies.isEmpty
                  ? Center(
                      child: Text(
                        'No se encontraron compañías',
                        style: GoogleFonts.outfit(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredCompanies.length,
                      itemBuilder: (context, index) {
                        final company = filteredCompanies[index];
                        final branches = company['branches'] as List<dynamic>? ?? [];
                        final isExpanded = company['isExpanded'] == true;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          color: theme.cardColor,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              ListTile(
                                onTap: () {
                                  setState(() {
                                    company['isExpanded'] = !isExpanded;
                                  });
                                },
                                leading: const CircleAvatar(
                                  backgroundColor: Color(0xFF05e265),
                                  child: Icon(Icons.business, color: Colors.white),
                                ),
                                title: Text(
                                  company['name'] ?? '',
                                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${company['celular']}'),
                                        const SizedBox(width: 12),
                                        const Icon(Icons.numbers, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${company['numero']}'),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.email, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text('${company['correo']}'),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${branches.length} Sucursales',
                                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueAccent),
                                    )
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.more_vert),
                                      onSelected: (value) {
                                        if (value == 'create_branch') {
                                          _showBranchForm(company);
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        const PopupMenuItem(
                                          value: 'create_branch',
                                          child: Row(
                                            children: [
                                              Icon(Icons.store_rounded, size: 20, color: Colors.blueAccent),
                                              SizedBox(width: 8),
                                              Text('Crear Sucursal'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined, size: 20),
                                              SizedBox(width: 8),
                                              Text('Editar'),
                                            ],
                                          ),
                                        ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                              SizedBox(width: 8),
                                              Text('Eliminar', style: TextStyle(color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isExpanded)
                                Container(
                                  color: theme.scaffoldBackgroundColor.withOpacity(0.5),
                                  child: Column(
                                    children: branches.isEmpty
                                        ? [
                                            Padding(
                                              padding: const EdgeInsets.all(16.0),
                                              child: Text('No hay sucursales registradas.',
                                                  style: GoogleFonts.outfit(color: Colors.grey)),
                                            )
                                          ]
                                        : branches.map<Widget>((branch) {
                                            final cashiers = branch['cashiers'] as List<dynamic>? ?? [];
                                            return Column(
                                              children: [
                                                const Divider(height: 1),
                                                ListTile(
                                                  contentPadding: const EdgeInsets.only(left: 40, right: 16),
                                                  leading: const Icon(Icons.store, color: Colors.blueAccent),
                                                  title: Text(branch['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                                                  subtitle: Text(
                                                    '${branch['correo']} | No: ${branch['numero']}\n${cashiers.length} Cajeros',
                                                    style: GoogleFonts.outfit(fontSize: 12),
                                                  ),
                                                  trailing: PopupMenuButton<String>(
                                                    icon: const Icon(Icons.more_horiz),
                                                    onSelected: (value) {
                                                      if (value == 'create_cashier') {
                                                        _showCashierForm(company, branch);
                                                      } else if (value == 'view_cashiers') {
                                                        _showCashiersList(company, branch);
                                                      }
                                                    },
                                                    itemBuilder: (context) => [
                                                      const PopupMenuItem(
                                                        value: 'create_cashier',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.person_add, size: 20, color: Color(0xFF05e265)),
                                                            SizedBox(width: 8),
                                                            Text('Crear Cajero'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'view_cashiers',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.people_outline, size: 20, color: Colors.blueAccent),
                                                            SizedBox(width: 8),
                                                            Text('Ver Cajeros'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'edit',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.edit_outlined, size: 20),
                                                            SizedBox(width: 8),
                                                            Text('Editar'),
                                                          ],
                                                        ),
                                                      ),
                                                      const PopupMenuItem(
                                                        value: 'delete',
                                                        child: Row(
                                                          children: [
                                                            Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                                            SizedBox(width: 8),
                                                            Text('Eliminar', style: TextStyle(color: Colors.red)),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                  ),
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
