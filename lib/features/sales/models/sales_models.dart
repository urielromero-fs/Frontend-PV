class CartItem {
  String id;
  String name;
  double price;
  double quantity;
  bool isBulk;
  double units;

  double? wholesaleMinUnits;
  double? wholesalePrice;
  double? originalPrice;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.units = 0.0,
    this.isBulk = false,
    this.wholesaleMinUnits,
    this.wholesalePrice,
    this.originalPrice,
  });
}

class Ticket {
  final String id;
  List<CartItem> items;
  double subtotal;
  double discount;
  double total;
  double? amountTendered;
  String paymentMethod;
  DateTime createdAt;

  Ticket({
    required this.id,
    List<CartItem>? items,
    this.subtotal = 0.0,
    this.discount = 0.0,
    this.total = 0.0,
    this.amountTendered,
    this.paymentMethod = 'Efectivo',
    DateTime? createdAt,
  })  : items = items ?? [],
        createdAt = createdAt ?? DateTime.now();
}
