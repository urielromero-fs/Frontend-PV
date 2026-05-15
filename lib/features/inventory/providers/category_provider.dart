import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryProvider extends ChangeNotifier {
  List<String> _categories = ["General", "Abarrotes", "Bebidas", "Limpieza"];
  static const String _storageKey = 'product_categories';

  List<String> get categories => _categories;

  CategoryProvider() {
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCategories = prefs.getStringList(_storageKey);
    if (savedCategories != null && savedCategories.isNotEmpty) {
      _categories = savedCategories;
    } else {
      // Default initial departments if none saved
      _categories = ["General", "Abarrotes", "Bebidas", "Limpieza"];
      await _saveCategories();
    }
    notifyListeners();
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, _categories);
  }

  Future<void> addCategory(String category) async {
    final trimmedCategory = category.trim();
    if (trimmedCategory.isNotEmpty && !_categories.contains(trimmedCategory)) {
      _categories.add(trimmedCategory);
      await _saveCategories();
      notifyListeners();
    }
  }

  Future<void> removeCategory(String category) async {
    if (_categories.contains(category)) {
      _categories.remove(category);
      await _saveCategories();
      notifyListeners();
    }
  }
}
