

List<dynamic> filterProducts({
  required List<dynamic> products,
  String searchQuery = '',
  String category = 'Todas',
  bool onlyBulk = false,
  String sortOption = 'Ninguno',
}) {
  
  List<dynamic> temp = List.from(products);

  // Búsqueda por nombre o barcode
  if (searchQuery.isNotEmpty) {
    final q = searchQuery.toLowerCase();
    temp = temp.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final barcode = (p['barcode'] ?? '').toString().toLowerCase();
      return name.contains(q) || barcode.contains(q);
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
    temp.sort((a, b) => (a['sellingPrice'] ?? 0).compareTo(b['sellingPrice'] ?? 0));
  } else if (sortOption == 'Precio Descendente') {
    temp.sort((a, b) => (b['sellingPrice'] ?? 0).compareTo(a['sellingPrice'] ?? 0));
  }

  return temp;
}