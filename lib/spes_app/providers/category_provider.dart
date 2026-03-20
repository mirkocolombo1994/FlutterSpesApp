import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/spes_app_database_helper.dart';

// Provider principale per la lista delle categorie
final categoryProvider = NotifierProvider<CategoryNotifier, List<Category>>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends Notifier<List<Category>> {
  @override
  List<Category> build() {
    loadCategories(); // Carica le categorie asincronamente
    return [];
  }

  // Legge tutte le categorie dal DB
  Future<void> loadCategories() async {
    final categories = await SpesAppDatabaseHelper.instance.getCategories();
    state = categories; // Aggiorna lo stato, notificando la UI
  }

  // Aggiunge una nuova categoria nel DB
  Future<void> addCategory(Category category) async {
    await SpesAppDatabaseHelper.instance.insertCategory(category);
    await loadCategories(); // Ricarica per riflettere i cambiamenti
  }

  // Elimina una categoria
  Future<void> deleteCategory(String id) async {
    await SpesAppDatabaseHelper.instance.deleteCategory(id);
    await loadCategories();
  }
}
