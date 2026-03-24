class Promotion {
  final String id;
  final String name;
  final String description;
  final double discountPercentage;
  final String storeId;
  final DateTime validFrom;
  final DateTime validUntil;

  Promotion({
    required this.id,
    required this.name,
    this.description = '',
    this.discountPercentage = 0.0,
    required this.storeId,
    required this.validFrom,
    required this.validUntil,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'discount_percentage': discountPercentage,
      'store_id': storeId,
      'valid_from': validFrom.millisecondsSinceEpoch,
      'valid_until': validUntil.millisecondsSinceEpoch,
    };
  }

  factory Promotion.fromMap(Map<String, dynamic> map) {
    return Promotion(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      discountPercentage: map['discount_percentage'] ?? 0.0,
      storeId: map['store_id'],
      validFrom: DateTime.fromMillisecondsSinceEpoch(map['valid_from']),
      validUntil: DateTime.fromMillisecondsSinceEpoch(map['valid_until']),
    );
  }
}
