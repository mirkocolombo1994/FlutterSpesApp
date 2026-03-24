import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import '../constants/app_strings.dart';

enum ProductSort { alphabetical, category }

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _searchQuery = '';
  ProductSort _sortBy = ProductSort.alphabetical;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Product> _getFilteredAndSortedProducts(List<Product> products) {
    // Filter
    var filtered = products.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final brandMatches = (p.brand ?? '').toLowerCase().contains(_searchQuery.toLowerCase());
      final barcodeMatches = p.barcode.contains(_searchQuery);
      return nameMatches || brandMatches || barcodeMatches;
    }).toList();

    // Sort
    if (_sortBy == ProductSort.alphabetical) {
      filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else {
      filtered.sort((a, b) {
        int catComp = (a.category ?? '').compareTo(b.category ?? '');
        if (catComp != 0) return catComp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    }

    return filtered;
  }

  void _confirmDelete(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.deleteProductTitle),
        content: Text('${AppStrings.deleteProductConfirmPrefix}${product.name}${AppStrings.deleteProductConfirmSuffix}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(AppStrings.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(productProvider.notifier).deleteProduct(product.barcode);
              Navigator.pop(ctx);
            },
            child: const Text(AppStrings.confirmAction, style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productProvider);
    final displayedProducts = _getFilteredAndSortedProducts(products);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: AppStrings.searchProductsHint,
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: const TextStyle(color: Colors.white, fontSize: 18),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              )
            : const Text(AppStrings.myProductsTitle),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchQuery = '';
                  _searchController.clear();
                }
              });
            },
          ),
          PopupMenuButton<ProductSort>(
            icon: const Icon(Icons.sort),
            onSelected: (sort) {
              setState(() {
                _sortBy = sort;
              });
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: ProductSort.alphabetical,
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha, size: 20),
                    SizedBox(width: 8),
                    Text(AppStrings.sortAlphabetical),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: ProductSort.category,
                child: Row(
                  children: [
                    Icon(Icons.category, size: 20),
                    SizedBox(width: 8),
                    Text(AppStrings.sortCategory),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: displayedProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty 
                        ? AppStrings.noSearchResults 
                        : AppStrings.noProductsRegistered,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: displayedProducts.length,
              itemBuilder: (context, index) {
                final product = displayedProducts[index];
                
                // HEADER CATEGORIA (se ordinato per categoria e cambia)
                bool showHeader = false;
                if (_sortBy == ProductSort.category) {
                  if (index == 0 || displayedProducts[index - 1].category != product.category) {
                    showHeader = true;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showHeader)
                      Padding(
                        padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
                        child: Text(
                          (product.category ?? AppStrings.unknownCategory).toUpperCase(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo.shade700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              // FOTO
                              Hero(
                                tag: 'product_${product.barcode}',
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.grey.shade100,
                                    image: (product.imageUrl != null && File(product.imageUrl!).existsSync())
                                        ? DecorationImage(
                                            image: FileImage(File(product.imageUrl!)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: (product.imageUrl == null || !File(product.imageUrl!).existsSync())
                                      ? Icon(Icons.shopping_bag_outlined, color: Colors.indigo.shade200, size: 35)
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // INFO
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    if (product.brand != null && product.brand!.isNotEmpty)
                                      Text(
                                        product.brand!,
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                      ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(Icons.qr_code, size: 14, color: Colors.indigo.shade300),
                                        const SizedBox(width: 4),
                                        Text(
                                          product.barcode,
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 12,
                                            color: Colors.indigo.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // AZIONI
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _confirmDelete(product),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newProduct),
      ),
    );
  }
}
