import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/store_provider.dart';
import 'shopping_list_detail_screen.dart';

class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    ShoppingListType selectedType = ShoppingListType.classic;
    String? selectedStoreId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          final stores = ref.read(storeProvider);
          
          return AlertDialog(
            title: const Text('Nuova Lista'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nome Lista'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ShoppingListType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo Lista'),
                    items: ShoppingListType.values.map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.name.toUpperCase()),
                    )).toList(),
                    onChanged: (val) {
                      setState(() {
                        selectedType = val!;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (selectedType == ShoppingListType.classic)
                    DropdownButtonFormField<String>(
                      value: selectedStoreId,
                      decoration: const InputDecoration(labelText: 'Seleziona Supermercato'),
                      items: stores.map((s) => DropdownMenuItem(
                        value: s.id,
                        child: Text(s.name),
                      )).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedStoreId = val;
                        });
                      },
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isEmpty) return;
                  if (selectedType == ShoppingListType.classic && selectedStoreId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scegli un supermercato per la lista classica')));
                    return;
                  }
                  
                  final newList = ShoppingList(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    type: selectedType,
                    storeId: selectedStoreId,
                    createdAt: DateTime.now(),
                  );
                  ref.read(shoppingListProvider.notifier).addList(newList);
                  Navigator.pop(ctx);
                },
                child: const Text('Crea'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lists = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Le mie Liste Spesa'),
      ),
      body: lists.isEmpty
          ? const Center(child: Text('Nessuna lista creata.'))
          : ListView.builder(
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Dismissible(
                  key: Key(list.id),
                  background: Container(color: Colors.red),
                  onDismissed: (direction) {
                    ref.read(shoppingListProvider.notifier).deleteList(list.id);
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: Icon(
                        list.type == ShoppingListType.superisparmio ? Icons.savings : Icons.list,
                        color: Colors.indigo,
                        size: 40,
                      ),
                      title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Tipo: ${list.type.name.toUpperCase()}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ShoppingListDetailScreen(shoppingList: list),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }
}
