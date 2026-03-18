import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/price_history.dart';
import '../services/spes_app_database_helper.dart';

// Provider che gestisce l'inserimento storico.
final priceHistoryProvider = Provider<PriceHistoryService>((ref) {
  return PriceHistoryService();
});

class PriceHistoryService {
  // Aggiunge un record allo storico prezzi
  Future<void> addPriceHistory(PriceHistory ph) async {
    await SpesAppDatabaseHelper.instance.insertPriceHistory(ph);
  }

  // Ottiene lo storico prezzi di un prodotto (per la modalità Prodotto)
  Future<List<PriceHistory>> getHistoryForProduct(String barcode) async {
    return await SpesAppDatabaseHelper.instance.getPriceHistoryForProduct(barcode);
  }

  // Ottiene lo storico prezzi in un supermercato (per la modalità Store)
  Future<List<PriceHistory>> getHistoryForStore(String storeId) async {
    return await SpesAppDatabaseHelper.instance.getPriceHistoryForStore(storeId);
  }
}
