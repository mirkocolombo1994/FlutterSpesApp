import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final double? unitPrice; // Prezzo al kg/l/pz
  final String? promoType; // Sconto, 1+1, etc.
  int quantity;

  CartItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    this.unitPrice,
    this.promoType,
    this.quantity = 1,
  });
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    // Se lo stesso prodotto allo stesso prezzo è già nel carrello, aumenta solo la quantità
    final idx = state.indexWhere((e) => e.barcode == item.barcode && e.price == item.price);
    if (idx >= 0) {
      final curr = state[idx];
      state = [
        ...state.sublist(0, idx),
        CartItem(
          id: curr.id,
          barcode: curr.barcode,
          name: curr.name,
          price: curr.price,
          unitPrice: curr.unitPrice,
          promoType: curr.promoType,
          quantity: curr.quantity + 1,
        ),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void clear() {
    state = [];
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(() => CartNotifier());
