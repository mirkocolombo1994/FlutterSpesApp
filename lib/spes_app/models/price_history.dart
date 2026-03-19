class PriceHistory {
  final String id;
  final String productBarcode;
  final String storeId;
  final double price;
  final int timestamp; // Unix timestamp in milliseconds
  final String? promoType;
  final int? promoValidUntil;

  PriceHistory({
    required this.id,
    required this.productBarcode,
    required this.storeId,
    required this.price,
    required this.timestamp,
    this.promoType,
    this.promoValidUntil,
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
    );
  }
}
