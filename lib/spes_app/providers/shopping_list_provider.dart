import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../services/spes_app_database_helper.dart';

// Provider per le liste della spesa
final shoppingListProvider = NotifierProvider<ShoppingListNotifier, List<ShoppingList>>(() {
  return ShoppingListNotifier();
});

class ShoppingListNotifier extends Notifier<List<ShoppingList>> {
  @override
  List<ShoppingList> build() {
    loadLists(); // Carica le liste asincronamente
    return [];
  }

  Future<void> loadLists() async {
    state = await SpesAppDatabaseHelper.instance.getShoppingLists();
  }

  // Aggiunge una nuova lista
  Future<void> addList(ShoppingList list) async {
    await SpesAppDatabaseHelper.instance.insertShoppingList(list);
    await loadLists();
  }

  // Aggiorna una lista esistente
  Future<void> updateList(ShoppingList list) async {
    await SpesAppDatabaseHelper.instance.updateShoppingList(list);
    await loadLists();
  }

  // Elimina una lista
  Future<void> deleteList(String id) async {
    await SpesAppDatabaseHelper.instance.deleteShoppingList(id);
    await loadLists();
  }
}

// Provider che gestisce il caricamento degli elementi (items) per una specifica lista della spesa.
final shoppingListItemsProvider = FutureProvider.family<List<ShoppingListItem>, String>((ref, listId) async {
  return await SpesAppDatabaseHelper.instance.getShoppingListItems(listId);
});

// Servizio per aggiungere/rimuovere articoli dalle liste
final shoppingListItemServiceProvider = Provider<ShoppingListItemService>((ref) {
  return ShoppingListItemService(ref);
});

class ShoppingListItemService {
  final Ref ref;

  ShoppingListItemService(this.ref);

  Future<void> addItem(ShoppingListItem item) async {
    await SpesAppDatabaseHelper.instance.insertShoppingListItem(item);
    // Invalida la cache degli item per questa lista per forzarne il ricaricamento nella UI
    ref.invalidate(shoppingListItemsProvider(item.listId));
  }

  Future<void> toggleItemCheck(ShoppingListItem item) async {
    final updatedItem = ShoppingListItem(
      id: item.id,
      listId: item.listId,
      productBarcode: item.productBarcode,
      quantity: item.quantity,
      isChecked: !item.isChecked,
    );
    await SpesAppDatabaseHelper.instance.updateShoppingListItem(updatedItem);
    ref.invalidate(shoppingListItemsProvider(item.listId));
  }

  Future<void> deleteItem(ShoppingListItem item) async {
    await SpesAppDatabaseHelper.instance.deleteShoppingListItem(item.id);
    ref.invalidate(shoppingListItemsProvider(item.listId));
  }
}
