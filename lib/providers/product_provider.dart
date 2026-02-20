import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class ProductProvider extends ChangeNotifier {
  List<dynamic> _allProducts = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Fetch global
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await InventoryService.getProducts();
      if (result['success'] == true) {
        _allProducts = result['data'];
      } else {
        _errorMessage = result['message'] ?? 'Error desconocido';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  void clearProducts() {
    _allProducts = [];
    notifyListeners();
  }
}
