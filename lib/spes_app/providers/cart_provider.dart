import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../services/promotion_engine.dart';
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
  final bool isPromoFree; // Indica se il prodotto è omaggio (es. il secondo in un 1+1)
  final String? parentId; // ID dell'articolo "pagante" a cui questo omaggio è collegato
  final double? originalPrice; // Prezzo originale da mostrare barrato
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
    this.isPromoFree = false,
    this.parentId,
    this.originalPrice,
    this.quantity = 1,
  });

  CartItem copyWith({
    String? id,
    String? barcode,
    String? name,
    double? price,
    double? unitPrice,
    String? promoType,
    String? imageUrl,
    CartItemStatus? status,
    bool? isPromoFree,
    String? parentId,
    double? originalPrice,
    int? quantity,
  }) {
    return CartItem(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      price: price ?? this.price,
      unitPrice: unitPrice ?? this.unitPrice,
      promoType: promoType ?? this.promoType,
      imageUrl: imageUrl ?? this.imageUrl,
      status: status ?? this.status,
      isPromoFree: isPromoFree ?? this.isPromoFree,
      parentId: parentId ?? this.parentId,
      originalPrice: originalPrice ?? this.originalPrice,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addItem(CartItem item) {
    // [DESIGN PATTERN: Composite / Registry Lookup]
    // Gestione accorpamento intelligente per prodotti in promozione.
    
    // 1. Se è un prodotto "omaggio" (child), cerchiamo se esiste già un omaggio dello stesso tipo per lo stesso genitore
    if (item.parentId != null) {
      final idx = state.indexWhere((e) => e.parentId == item.parentId && e.barcode == item.barcode && e.isPromoFree);
      if (idx >= 0) {
        final curr = state[idx];
        state = [
          ...state.sublist(0, idx),
          curr.copyWith(quantity: curr.quantity + item.quantity),
          ...state.sublist(idx + 1),
        ];
        return;
      }
    }

    // 2. Se è un prodotto "pagante" (parent) con promo attiva, lo accorpiamo se barcode e promo coincidono
    if (item.promoType != null && !item.isPromoFree) {
       final idx = state.indexWhere((e) => e.barcode == item.barcode && e.promoType == item.promoType && !e.isPromoFree);
       if (idx >= 0) {
        final curr = state[idx];
        state = [
          ...state.sublist(0, idx),
          curr.copyWith(quantity: curr.quantity + item.quantity),
          ...state.sublist(idx + 1),
        ];
        return;
      }
    }

    // 3. Altrimenti, se lo stesso prodotto allo stesso prezzo è già nel carrello, aumenta solo la quantità
    final idx = state.indexWhere(
      (e) => e.barcode == item.barcode && e.price == item.price && !e.isPromoFree && e.parentId == null,
    );
    if (idx >= 0) {
      final curr = state[idx];
      state = [
        ...state.sublist(0, idx),
        curr.copyWith(quantity: curr.quantity + item.quantity),
        ...state.sublist(idx + 1),
      ];
    } else {
      state = [...state, item];
    }
  }

  /// [DESIGN PATTERN: State Transition / Reactive Update]
  /// Rimuove un articolo dal carrello.
  /// Se viene rimosso un articolo "padre", gli articoli omaggio collegati perdono il beneficio
  /// della promozione e tornano al loro prezzo originale.
  void removeItem(String id) {
    state = state.where((item) => item.id != id).map((item) {
      if (item.parentId == id) {
        // Se l'elemento era collegato a quello rimosso, torna a prezzo pieno
        return item.copyWith(
          isPromoFree: false,
          parentId: null,
          price: item.originalPrice ?? item.price,
          originalPrice: null,
        );
      }
      return item;
    }).toList();
  }

  /// [DESIGN PATTERN: Reactive Sync / State Transition]
  /// Aggiorna la quantità di un articolo. La sincronizzazione degli omaggi in aumento è gestita dalla UI,
  /// ma il REVERT al decremento è gestito qui per sicurezza.
  void updateQuantity(String id, int newQuantity) {
    if (newQuantity <= 0) return;
    
    final itemIdx = state.indexWhere((e) => e.id == id);
    if (itemIdx == -1) return;
    final parentItem = state[itemIdx];

    List<CartItem> newState = state.map((item) {
      if (item.id == id) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    // Revert logic: The user decreased the paid quantity, check if we must invalidate some free items
    if (newQuantity < parentItem.quantity && !parentItem.isPromoFree) {
      final rule = PromotionEngine.getRule(parentItem.promoType);
      if (rule != null) {
        final allowedFreeCount = (newQuantity ~/ rule.paidPiecesPerSet).toInt() * rule.freeItemsCount.toInt();
        
        final connectedFreeItems = newState.where((i) => i.parentId == id && i.isPromoFree).toList();
        final currentFreeCount = connectedFreeItems.fold<int>(0, (sum, i) => sum + i.quantity);

        if (currentFreeCount > allowedFreeCount) {
          final int excessAmount = currentFreeCount - allowedFreeCount;
          
          if (allowedFreeCount <= 0) {
            // Nessun omaggio consentito, li trasformiamo tutti in paganti svincolati
            newState = newState.map((item) {
               if (item.parentId == id && item.isPromoFree) {
                 return item.copyWith(
                   isPromoFree: false,
                   parentId: null,
                   price: item.originalPrice ?? item.price,
                   originalPrice: null,
                 );
               }
               return item;
            }).toList();
          } else {
             // Riduciamo la quantità dell'omaggio a quella massima consentita
             newState = newState.map((item) {
               if (item.parentId == id && item.isPromoFree) {
                 return item.copyWith(quantity: allowedFreeCount);
               }
               return item;
             }).toList();
             
             // Aggiungiamo il residuo come nuovo prodotto pagante
             final freeItemRef = connectedFreeItems.first;
             newState.add(freeItemRef.copyWith(
               id: const Uuid().v4(),
               quantity: excessAmount,
               isPromoFree: false,
               parentId: null,
               price: freeItemRef.originalPrice ?? freeItemRef.price,
               originalPrice: null,
             ));
          }
        }
      }
    }

    state = newState;
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
      // Gli omaggi non ricalcolano il prezzo (rimangono 0)
      if (item.isPromoFree) {
        newList.add(item);
        continue;
      }

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
        item.copyWith(
          price: newPrice,
          promoType: promo,
          imageUrl: product?.imageUrl,
          status: status,
        ),
      );
    }
    state = newList;
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  () => CartNotifier(),
);
