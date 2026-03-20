import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';

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
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailScreen(product: product),
                        ),
                      );
                    },
                    leading: product.imageUrl != null && File(product.imageUrl!).existsSync()
                        ? Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(File(product.imageUrl!)),
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : const Icon(Icons.inventory, color: Colors.blueGrey, size: 40),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                        if (product.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.category!,
                              style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (product.brand != null && product.brand!.isNotEmpty)
                          Text('Marca: ${product.brand}'),
                        Text('Barcode: ${product.barcode}'),
                        if (product.weight != null)
                          Text('Formato: ${product.weight} ${product.weightUnit ?? ""}'),
                        if (product.pricePerKg != null && product.pricePerKg! > 0)
                          Text(
                            'Riferimento: ${product.pricePerKg!.toStringAsFixed(2)} €/unità',
                            style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.w500),
                          ),
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
