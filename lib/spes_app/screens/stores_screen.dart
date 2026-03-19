import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/store_provider.dart';
import 'add_store_screen.dart';

class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storeProvider);
    final newlyAddedId = ref.watch(newlyAddedStoreIdProvider);
    
    if (newlyAddedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reset directly by invalidating or setting to null, so it only highlights the first time it's built
        ref.read(newlyAddedStoreIdProvider.notifier).setId(null);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supermercati'),
      ),
      body: stores.isEmpty
          ? const Center(child: Text('Nessun supermercato salvato. Aggiungine uno!'))
          : ListView.builder(
              itemCount: stores.length,
              itemBuilder: (context, index) {
                final store = stores[index];
                final isNew = store.id == newlyAddedId;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: isNew ? RoundedRectangleBorder(
                    side: BorderSide(color: Colors.green.shade600, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ) : null,
                  elevation: isNew ? 8 : 1,
                  child: ListTile(
                    leading: isNew 
                      ? const Icon(Icons.new_releases, color: Colors.green, size: 40)
                      : Icon(Icons.storefront, color: store.isClosed ? Colors.grey : Colors.indigo, size: 40),
                    title: Text(
                      isNew ? '${store.name} (NUOVO!)' : store.name, 
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isNew ? Colors.green.shade800 : null,
                        decoration: store.isClosed ? TextDecoration.lineThrough : null,
                      )
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (store.isClosed)
                          const Text('CHIUSO DEFINITIVAMENTE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        if (store.chain != null && store.chain!.isNotEmpty) 
                          Text('Catena: ${store.chain}'),
                        if (store.phone != null && store.phone!.isNotEmpty) 
                          Text('Tel: ${store.phone}'),
                        if (store.latitude != null && store.longitude != null)
                          const Text('Posizione salvata sulla mappa', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
                    trailing: const Icon(Icons.edit, color: Colors.grey),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddStoreScreen(storeToEdit: store)),
                      );
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStoreScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
