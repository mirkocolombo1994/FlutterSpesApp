class PriceHistory {
  final String id;
  final String productBarcode;
  final String storeId;
  final double price;
  final int timestamp; // Unix timestamp in milliseconds
  final String? promoType;
  final int? promoValidUntil;
  final double? unitPrice;    // Prezzo calcolato per Unità (es. al Kg)
  final double? weightRecorded; // Peso inserito al momento della rilevazione

  PriceHistory({
    required this.id,
    required this.productBarcode,
    required this.storeId,
    required this.price,
    required this.timestamp,
    this.promoType,
    this.promoValidUntil,
    this.unitPrice,
    this.weightRecorded,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_barcode': productBarcode,
      'store_id': storeId,
      'price': price,
      'timestamp': timestamp,
      'promo_type': promoType,
      'promo_valid_until': promoValidUntil,
      'unit_price': unitPrice,
      'weight_recorded': weightRecorded,
    };
  }

  factory PriceHistory.fromMap(Map<String, dynamic> map) {
    return PriceHistory(
      id: map['id'],
      productBarcode: map['product_barcode'],
      storeId: map['store_id'],
      price: map['price'],
      timestamp: map['timestamp'],
      promoType: map['promo_type'],
      promoValidUntil: map['promo_valid_until'],
      unitPrice: map['unit_price'],
      weightRecorded: map['weight_recorded'],
    );
  }
}
