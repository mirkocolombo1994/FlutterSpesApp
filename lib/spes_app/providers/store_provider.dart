import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/store.dart';
import '../services/spes_app_database_helper.dart';

// Provider principale per la lista dei supermercati
final storeProvider = NotifierProvider<StoreNotifier, List<Store>>(() {
  return StoreNotifier();
});

class StoreNotifier extends Notifier<List<Store>> {
  @override
  List<Store> build() {
    loadStores(); // Carica i supermercati asincronamente
    return [];
  }

  // Legge tutti i supermercati dal DB
  Future<void> loadStores() async {
    final stores = await SpesAppDatabaseHelper.instance.getStores();
    state = stores; // Aggiorna lo stato, notificando la UI
  }

  // Aggiunge un nuovo supermercato nel DB
  Future<void> addStore(Store store) async {
    await SpesAppDatabaseHelper.instance.insertStore(store);
    await loadStores(); // Ricarica per riflettere i cambiamenti
  }

  // Aggiorna un supermercato esistente
  Future<void> updateStore(Store store) async {
    await SpesAppDatabaseHelper.instance.updateStore(store);
    await loadStores();
  }

  // Elimina un supermercato
  Future<void> deleteStore(String id) async {
    await SpesAppDatabaseHelper.instance.deleteStore(id);
    await loadStores();
  }
}
