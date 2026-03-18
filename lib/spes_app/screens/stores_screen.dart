import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/store_provider.dart';
import 'add_store_screen.dart';

class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storeProvider);

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
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.storefront, color: Colors.indigo, size: 40),
                    title: Text(store.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (store.chain != null && store.chain!.isNotEmpty) 
                          Text('Catena: ${store.chain}'),
                        if (store.phone != null && store.phone!.isNotEmpty) 
                          Text('Tel: ${store.phone}'),
                        if (store.latitude != null && store.longitude != null)
                          const Text('Posizione salvata sulla mappa', style: TextStyle(color: Colors.green, fontSize: 12)),
                      ],
                    ),
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
