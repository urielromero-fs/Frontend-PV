import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../reports/services/branches_service.dart'; 



// class CategoryProvider extends ChangeNotifier {
//   List<String> _categories = ["General", "Abarrotes", "Bebidas", "Limpieza"];
//   static const String _storageKey = 'product_categories';

//   List<String> get categories => _categories;

//   CategoryProvider() {
//     _loadCategories();
//   }

//   Future<void> _loadCategories() async {
//     final prefs = await SharedPreferences.getInstance();
//     final savedCategories = prefs.getStringList(_storageKey);
//     if (savedCategories != null && savedCategories.isNotEmpty) {
//       _categories = savedCategories;
//     } else {
//       // Default initial departments if none saved
//       _categories = ["General", "Abarrotes", "Bebidas", "Limpieza"];
//       await _saveCategories();
//     }
//     notifyListeners();
//   }

//   Future<void> _saveCategories() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setStringList(_storageKey, _categories);
//   }

//   Future<void> addCategory(String category) async {
//     final trimmedCategory = category.trim();
//     if (trimmedCategory.isNotEmpty && !_categories.contains(trimmedCategory)) {
//       _categories.add(trimmedCategory);
//       await _saveCategories();
//       notifyListeners();
//     }
//   }

//   Future<void> removeCategory(String category) async {
//     if (_categories.contains(category)) {
//       _categories.remove(category);
//       await _saveCategories();
//       notifyListeners();
//     }
//   }
// }



class CategoryProvider extends ChangeNotifier {
  List<String> _categories = [];

  List<String> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Obtener categorías desde backend
  Future<void> loadCategories(String locationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BranchesService.getCategories(
        id: locationId,
      );

      if (response['success']) {
        final data = response['data'];

        // Ajusta esto según tu response real
        // Ejemplo esperado:
        // {
        //   success: true,
        //   data: {
        //      categories: [...]
        //   }
        // }

        final List<dynamic> categoriesData =
            data['categories'] ?? [];

        _categories =
            categoriesData.map((e) => e.toString()).toList();
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Agregar categoría
  Future<bool> addCategory({  
    required String locationId,
    required String category,
  }) async {
    final trimmedCategory = category.trim();

    if (trimmedCategory.isEmpty) {
      _error = 'La categoría no puede estar vacía';
      notifyListeners();
      return false;
    }

    if (_categories.contains(trimmedCategory)) {
      _error = 'La categoría ya existe';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BranchesService.addCategory(
        id: locationId,
        category: trimmedCategory,
      );

      if (response['success']) {
        _categories.add(trimmedCategory);

        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  /// Eliminar categoría
  Future<bool> removeCategory({
    required String locationId,
    required String category,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await BranchesService.deleteCategories(
        id: locationId,
      );

      if (response['success']) {
        _categories.remove(category);

        _isLoading = false;
        notifyListeners();

        return true;
      } else {
        _error = response['message'];
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();

    return false;
  }

  /// Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }
}