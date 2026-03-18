import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/product_provider.dart';
import 'add_product_screen.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prodotti'),
      ),
      body: products.isEmpty
          ? const Center(child: Text('Nessun prodotto trovato.'))
          : ListView.builder(
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: const Icon(Icons.inventory, color: Colors.blueGrey, size: 40),
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brand != null && product.brand!.isNotEmpty)
                          Text('Marca: ${product.brand}'),
                        Text('Barcode: ${product.barcode}'),
                        if (product.weight != null)
                          Text('${product.weight} ${product.weightUnit ?? ""}'),
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
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
