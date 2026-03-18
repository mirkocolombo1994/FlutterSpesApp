class Product {
  final String barcode;
  final String name;
  final String? description;
  final String? brand;
  final double? weight;
  final String? weightUnit;

  Product({
    required this.barcode,
    required this.name,
    this.description,
    this.brand,
    this.weight,
    this.weightUnit,
  });

  Map<String, dynamic> toMap() {
    return {
      'barcode': barcode,
      'name': name,
      'description': description,
      'brand': brand,
      'weight': weight,
      'weight_unit': weightUnit,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      barcode: map['barcode'],
      name: map['name'],
      description: map['description'],
      brand: map['brand'],
      weight: map['weight'],
      weightUnit: map['weight_unit'],
    );
  }
}
