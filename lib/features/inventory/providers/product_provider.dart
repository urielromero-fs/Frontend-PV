import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class ProductProvider extends ChangeNotifier {
  List<dynamic> _allProducts = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;


  //Initial load

  Future<void> fetchInitialProducts({String? branchId}) async {

      _isLoading = true;
      _errorMessage = '';
      notifyListeners();

      try{
        final result = await InventoryService.getFirstProducts();

        
        if(result['success'] == true){
          _allProducts = result['data'];

          
        } else {
          _errorMessage = result['message'] ?? 'Error desconocido';
        }
      }catch(e){
        _errorMessage = e.toString();
      } 

      _isLoading = false;
      notifyListeners(); 

      //Start load of all products in background
       _fetchAllProductsInBackground(branchId);

  }


  // Background load of all products
  Future<void> _fetchAllProductsInBackground(String? branchId) async {
    try {
      final result = await InventoryService.getProducts(branchId);

      
      if (result['success'] == true) {
        _allProducts = result['data'];
        notifyListeners();
      }
    } catch (e) {
      // No need to set error message for background load
    }
  }




  // Fetch global
  Future<void> fetchProducts({String? branchId}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    

    try {
      final result = await InventoryService.getProducts(branchId);

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
