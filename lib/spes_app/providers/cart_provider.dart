import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'price_history_provider.dart';
import 'product_provider.dart';

enum CartItemStatus { ok, warning, error }

class CartItem {
  final String id;
  final String barcode;
  final String name;
  final double price;
  final double? unitPrice; // Prezzo al kg/l/pz
  final String? promoType; // Sconto, 1+1, etc.
  final String? imageUrl;
  final CartItemStatus status;
  int quantity;

  CartItem({
    required this.id,
    required this.barcode,
    required this.name,
    required this.price,
    this.unitPrice,
    this.promoType,
    this.imageUrl,
    this.status = CartItemStatus.ok,
    this.quantity = 1,
  });
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    // Se lo stesso prodotto allo stesso prezzo è già nel carrello, aumenta solo la quantità
    final idx = state.indexWhere(
      (e) => e.barcode == item.barcode && e.price == item.price,
    );
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
          imageUrl: curr.imageUrl,
          status: curr.status,
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

  void updateQuantity(String id, int newQuantity) {
    if (newQuantity <= 0) return;
    state = state.map((item) {
      if (item.id == id) {
        return CartItem(
          id: item.id,
          barcode: item.barcode,
          name: item.name,
          price: item.price,
          unitPrice: item.unitPrice,
          promoType: item.promoType,
          imageUrl: item.imageUrl,
          status: item.status,
          quantity: newQuantity,
        );
      }
      return item;
    }).toList();
  }

  void clear() {
    state = [];
  }

  // Aggiorna i prezzi di tutti i prodotti in base al nuovo supermercato selezionato
  Future<void> refreshPrices(String storeId, WidgetRef ref) async {
    final historyNotifier = ref.read(priceHistoryProvider);
    final products = ref.read(productProvider);

    List<CartItem> newList = [];
    for (var item in state) {
      final history = await historyNotifier.getHistoryForProduct(item.barcode);
      final storeHistory = history
          .where((h) => h.storeId == storeId)
          .firstOrNull;
      final product = products
          .where((p) => p.barcode == item.barcode)
          .firstOrNull;

      CartItemStatus status = CartItemStatus.ok;
      double newPrice = 0.0;
      String? promo;

      if (storeHistory == null) {
        status = CartItemStatus.error; // Prodotto mai visto in questo negozio
      } else {
        newPrice = storeHistory.price;
        promo = storeHistory.promoType;
        if (newPrice <= 0) {
          status = CartItemStatus.warning; // Prezzo mancante o nullo
        }
      }

      newList.add(
        CartItem(
          id: item.id,
          barcode: item.barcode,
          name: item.name,
          price: newPrice,
          unitPrice: item.unitPrice,
          promoType: promo,
          imageUrl: product?.imageUrl,
          status: status,
          quantity: item.quantity,
        ),
      );
    }
    state = newList;
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  () => CartNotifier(),
);
