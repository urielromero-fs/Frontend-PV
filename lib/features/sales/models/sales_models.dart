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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'isBulk': isBulk,
        'units': units,
        'wholesaleMinUnits': wholesaleMinUnits,
        'wholesalePrice': wholesalePrice,
        'originalPrice': originalPrice,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num).toDouble(),
        isBulk: json['isBulk'],
        units: (json['units'] as num).toDouble(),
        wholesaleMinUnits: (json['wholesaleMinUnits'] as num?)?.toDouble(),
        wholesalePrice: (json['wholesalePrice'] as num?)?.toDouble(),
        originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      );




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



  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'discount': discount,
        'total': total,
        'amountTendered': amountTendered,
        'paymentMethod': paymentMethod,
        'createdAt': createdAt.toIso8601String(),
      };


  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'],
        items: (json['items'] as List<dynamic>)
            .map((item) => CartItem.fromJson(item))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        discount: (json['discount'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        amountTendered: (json['amountTendered'] as num?)?.toDouble(),
        paymentMethod: json['paymentMethod'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
