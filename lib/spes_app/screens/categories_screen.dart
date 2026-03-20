import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';
import '../providers/category_provider.dart';
import '../constants/app_strings.dart';

/// Schermata per la gestione delle categorie dei prodotti.
/// Permette di visualizzare, aggiungere ed eliminare categorie.
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  // Controller per il campo di testo nel dialogo di aggiunta
  final _textFieldController = TextEditingController();

  @override
  void dispose() {
    _textFieldController.dispose();
    super.dispose();
  }

  /// Crea una nuova categoria e la salva tramite il provider
  void _addCategory() {
    final name = _textFieldController.text.trim();
    if (name.isNotEmpty) {
      final category = Category(
        id: const Uuid().v4(), // Genera un ID univoco
        name: name,
      );
      ref.read(categoryProvider.notifier).addCategory(category);
      _textFieldController.clear();
      Navigator.pop(context); // Chiude il dialogo
    }
  }

  /// Mostra un dialogo di input per inserire il nome della nuova categoria
  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.newCategory),
        content: TextField(
          controller: _textFieldController,
          decoration: const InputDecoration(hintText: AppStrings.categoryNameHint),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: _addCategory,
            child: const Text(AppStrings.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ascolta il provider per reagire ai cambiamenti della lista categorie
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.manageCategories),
      ),
      body: categories.isEmpty
          ? const Center(child: Text(AppStrings.noCategoriesDefined))
          : ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return ListTile(
                  title: Text(category.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // Elimina la categoria selezionata
                      ref.read(categoryProvider.notifier).deleteCategory(category.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: AppStrings.addCategoryTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
