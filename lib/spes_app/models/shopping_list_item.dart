class ShoppingListItem {
  final String id;
  final String listId;
  final String productBarcode;
  final int quantity;
  final bool isChecked;
  final String? storeId; // Usato per la modalità MIX per selezionare il punto vendita per ogni singolo prodotto

  ShoppingListItem({
    required this.id,
    required this.listId,
    required this.productBarcode,
    required this.quantity,
    this.isChecked = false,
    this.storeId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'list_id': listId,
      'product_barcode': productBarcode,
      'quantity': quantity,
      'is_checked': isChecked ? 1 : 0,
      'store_id': storeId,
    };
  }

  factory ShoppingListItem.fromMap(Map<String, dynamic> map) {
    return ShoppingListItem(
      id: map['id'],
      listId: map['list_id'],
      productBarcode: map['product_barcode'],
      quantity: map['quantity'],
      isChecked: map['is_checked'] == 1,
      storeId: map['store_id'],
    );
  }
}
