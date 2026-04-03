import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category.dart';
import '../services/spes_app_database_helper.dart';
import './open_food_facts_provider.dart';

// Provider principale per la lista delle categorie
// Utilizza un Notifier per gestire lo stato in modo reattivo
final categoryProvider = NotifierProvider<CategoryNotifier, List<Category>>(() {
  return CategoryNotifier();
});

class CategoryNotifier extends Notifier<List<Category>> {
  @override
  List<Category> build() {
    loadCategories().then((_) {
      if (state.isEmpty) {
        syncWithOpenFoodFacts();
      }
    });
    return [];
  }

  /// Legge tutte le categorie dal database e aggiorna lo stato della UI
  Future<void> loadCategories() async {
    final categories = await SpesAppDatabaseHelper.instance.getCategories();
    state = categories; // Notifica automaticamente tutti i widget in ascolto
  }

  /// Aggiunge una nuova categoria e ricarica l'elenco
  Future<void> addCategory(Category category) async {
    await SpesAppDatabaseHelper.instance.insertCategory(category);
    await loadCategories(); 
  }

  /// Elimina una categoria tramite ID e aggiorna l'interfaccia
  Future<void> deleteCategory(String id) async {
    await SpesAppDatabaseHelper.instance.deleteCategory(id);
    await loadCategories();
  }

  /// Sincronizza le categorie con Open Food Facts
  Future<void> syncWithOpenFoodFacts() async {
    final offService = ref.read(openFoodFactsProvider);
    final commonCategories = await offService.fetchCommonCategories();
    
    for (var cat in commonCategories) {
      await SpesAppDatabaseHelper.instance.insertCategory(cat);
    }
    await loadCategories();
  }
}
