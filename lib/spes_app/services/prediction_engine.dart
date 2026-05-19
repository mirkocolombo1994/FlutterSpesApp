import '../models/product.dart';
import '../models/price_history.dart';
import '../models/shopping_list.dart';
import 'spes_app_database_helper.dart';

class PredictionEngine {
  static final PredictionEngine instance = PredictionEngine._init();
  PredictionEngine._init();

  /// Valuta se il prezzo inserito è un affare confrontandolo con lo storico prezzi locale.
  Future<String> evaluatePriceDeal(String barcode, String storeId, double enteredPrice) async {
    final history = await SpesAppDatabaseHelper.instance.getPriceHistoryForProduct(barcode);
    if (history.isEmpty) {
      return ''; // Nessuno storico disponibile per fare il confronto
    }

    // Filtra i prezzi rilevati per lo store corrente (o usa tutto il database come confronto secondario)
    final storePrices = history.where((p) => p.storeId == storeId).map((p) => p.price).toList();
    final allPrices = history.map((p) => p.price).toList();

    final pricesToCompare = storePrices.isNotEmpty ? storePrices : allPrices;

    double minPrice = pricesToCompare.reduce((a, b) => a < b ? a : b);
    double sum = pricesToCompare.reduce((a, b) => a + b);
    double avgPrice = sum / pricesToCompare.length;

    if (enteredPrice <= minPrice * 1.01) {
      return 'excellent'; // 🔥 Ottimo Affare!
    } else if (enteredPrice < avgPrice * 0.96) {
      return 'good'; // 👍 Buon Prezzo
    } else if (enteredPrice > avgPrice * 1.08) {
      return 'expensive'; // ⚠️ Prezzo Elevato
    } else {
      return 'average'; // Prezzo nella Media
    }
  }

  /// Calcola i prodotti suggeriti per il riacquisto in base allo storico.
  Future<List<Product>> getReplenishmentSuggestions() async {
    final allProducts = await SpesAppDatabaseHelper.instance.getProducts();
    final List<Product> suggestions = [];

    final now = DateTime.now();

    for (final product in allProducts) {
      final history = await SpesAppDatabaseHelper.instance.getPriceHistoryForProduct(product.barcode);
      if (history.length < 2) {
        // Se abbiamo solo 0 o 1 acquisti, non possiamo calcolare un intervallo reale.
        // Come fallback intelligente, se il prodotto è stato acquistato più di 15 giorni fa, lo proponiamo
        if (history.isNotEmpty) {
          final lastPurchase = DateTime.fromMillisecondsSinceEpoch(history.first.timestamp);
          if (now.difference(lastPurchase).inDays >= 14) {
            suggestions.add(product);
          }
        }
        continue;
      }

      // Ordina lo storico per data decrescente
      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // Calcola le differenze in giorni tra acquisti consecutivi
      final List<int> intervals = [];
      for (int i = 0; i < history.length - 1; i++) {
        final date1 = DateTime.fromMillisecondsSinceEpoch(history[i].timestamp);
        final date2 = DateTime.fromMillisecondsSinceEpoch(history[i + 1].timestamp);
        final diff = date1.difference(date2).inDays;
        if (diff > 0) {
          intervals.add(diff);
        }
      }

      if (intervals.isEmpty) continue;

      // Media degli intervalli di riacquisto
      double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      // Impediamo intervalli irrealisticamente troppo corti
      if (avgInterval < 2) avgInterval = 2;

      final lastPurchaseDate = DateTime.fromMillisecondsSinceEpoch(history.first.timestamp);
      final daysSinceLastPurchase = now.difference(lastPurchaseDate).inDays;

      // Se il tempo trascorso è vicino o supera l'intervallo medio di acquisto, è in esaurimento!
      if (daysSinceLastPurchase >= (avgInterval - 1)) {
        suggestions.add(product);
      }
    }

    // Ordina i suggerimenti in modo da restituirne al massimo 8, dando la priorità a quelli più urgenti
    return suggestions.take(8).toList();
  }

  /// Estima il budget totale di una lista della spesa classica in base ai prezzi storici.
  Future<double> estimateListBudget(String listId, String storeId) async {
    final items = await SpesAppDatabaseHelper.instance.getShoppingListItems(listId);
    double estimatedTotal = 0.0;

    for (final item in items) {
      final barcode = item.productBarcode;
      double priceEstimate = 1.50; // Prezzo stimato di fallback globale

      if (barcode.isNotEmpty) {
        // Cerca prima il prezzo in questo specifico store
        final history = await SpesAppDatabaseHelper.instance.getPriceHistoryForProduct(barcode);
        if (history.isNotEmpty) {
          final storePrices = history.where((p) => p.storeId == storeId).toList();
          if (storePrices.isNotEmpty) {
            // Ordina per data per prendere il più recente
            storePrices.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            priceEstimate = storePrices.first.price;
          } else {
            // Se non c'è in questo store, prendiamo la media di altri store
            final sum = history.map((p) => p.price).reduce((a, b) => a + b);
            priceEstimate = sum / history.length;
          }
        }
      }

      estimatedTotal += priceEstimate * item.quantity;
    }

    return estimatedTotal;
  }
}
