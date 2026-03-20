import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/spes_app_database_helper.dart';

// Provider principale per la lista dei prodotti
final productProvider = NotifierProvider<ProductNotifier, List<Product>>(() {
  return ProductNotifier();
});

class ProductNotifier extends Notifier<List<Product>> {
  @override
  List<Product> build() {
    loadProducts(); // Carica i prodotti asincronamente
    return [];
  }

  // Legge tutti i prodotti dal DB
  Future<void> loadProducts() async {
    final products = await SpesAppDatabaseHelper.instance.getProducts();
    state = products; // Notifica la UI
  }

  // Aggiunge un nuovo prodotto al DB
  Future<void> addProduct(Product product) async {
    await SpesAppDatabaseHelper.instance.insertProduct(product);
    await loadProducts(); // Ricarica la lista aggiornata
  }

  // Aggiorna un prodotto esistente
  Future<void> updateProduct(Product product) async {
    await SpesAppDatabaseHelper.instance.insertProduct(product); // insertProduct usa ConflictAlgorithm.replace
    await loadProducts(); // Ricarica la lista aggiornata
  }
}
