import 'package:diacritic/diacritic.dart';

bool containsAccent(String s) {
  
  final accents = 'áàäâãéèëêíìïîóòöôõúùüûñÁÀÄÂÃÉÈËÊÍÌÏÎÓÒÖÔÕÚÙÜÛÑ';
  return s.split('').any((c) => accents.contains(c));
}


List<dynamic> filterProducts({
  required List<dynamic> products,
  String searchQuery = '',
  String category = 'Todas',
  bool onlyBulk = false,
  String sortOption = 'Ninguno',
  String stockStatus = 'Todos',
}) {
  List<dynamic> temp = List.from(products);

  // Filtro por Stock
  if (stockStatus == 'Bajo Stock') {
    temp = temp.where((p) => (p['units'] ?? 0) < 5 && (p['units'] ?? 0) > 0).toList();
  } else if (stockStatus == 'Sin Stock') {
    temp = temp.where((p) => (p['units'] ?? 0) == 0).toList();
  }

  // Búsqueda por nombre o barcode
  if (searchQuery.isNotEmpty) {


    final queryHasAccent = containsAccent(searchQuery);
    final q = searchQuery.toLowerCase();
    
    temp = temp.where((p) {

      final name = (p['name'] ?? '').toString().toLowerCase();
      final barcode = (p['barcode'] ?? '').toString().toLowerCase();


      if (queryHasAccent) {
       
        return name.contains(q) || barcode.contains(q);
      } else {
        
        final nameNormalized = removeDiacritics(name);
        final barcodeNormalized = removeDiacritics(barcode);
        final qNormalized = removeDiacritics(q);
        return nameNormalized.contains(qNormalized) || barcodeNormalized.contains(qNormalized);
      }
      
    }).toList();
  }

  // Filtro por categoría
  if (category != 'Todas') {
    temp = temp.where((p) => p['category'] == category).toList();
  }

  // Solo granel
  if (onlyBulk) {
    temp = temp.where((p) => p['isBulk'] == true).toList();
  }

  // Ordenamiento
  if (sortOption == 'Precio Ascendente') {
    temp.sort(
      (a, b) => (a['sellingPrice'] ?? 0).compareTo(b['sellingPrice'] ?? 0),
    );
  } else if (sortOption == 'Precio Descendente') {
    temp.sort(
      (a, b) => (b['sellingPrice'] ?? 0).compareTo(a['sellingPrice'] ?? 0),
    );
  }

  return temp;
}
