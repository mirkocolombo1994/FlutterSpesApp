import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/store_provider.dart';
import 'add_store_screen.dart';
import '../constants/app_strings.dart';

class StoresScreen extends ConsumerWidget {
  const StoresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stores = ref.watch(storeProvider);
    final newlyAddedId = ref.watch(newlyAddedStoreIdProvider);
    
    if (newlyAddedId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reset after a delay so the user can see the highlight
        Future.delayed(const Duration(seconds: 3), () {
           ref.read(newlyAddedStoreIdProvider.notifier).setId(null);
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navSupermercati),
      ),
      body: stores.isEmpty
          ? const Center(child: Text(AppStrings.noStoresSaved))
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
                      isNew ? '${store.name} (${AppStrings.newStoreIndicator})' : store.name, 
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
                          const Text(AppStrings.storeClosedDefinitively, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        if (store.chain != null && store.chain!.isNotEmpty) 
                          Text('${AppStrings.storeChainPrefix} ${store.chain}'),
                        if (store.phone != null && store.phone!.isNotEmpty) 
                          Text('${AppStrings.storePhonePrefix} ${store.phone}'),
                        if (store.latitude != null && store.longitude != null)
                          const Text(AppStrings.locationSavedOnMap, style: TextStyle(color: Colors.green, fontSize: 12)),
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
