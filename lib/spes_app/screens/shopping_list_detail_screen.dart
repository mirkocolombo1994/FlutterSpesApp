import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';
import '../models/product.dart';
import '../models/store.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';
import '../providers/price_history_provider.dart';
import 'barcode_scanner_screen.dart';

class ShoppingListDetailScreen extends ConsumerStatefulWidget {
  final ShoppingList shoppingList;

  const ShoppingListDetailScreen({super.key, required this.shoppingList});

  @override
  ConsumerState<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends ConsumerState<ShoppingListDetailScreen> {
  
  // Calcolo asincrono del totale e dell'assegnazione store per supeRisparmio
  Future<Map<String, dynamic>> _calculateTotalAndAssignments(List<ShoppingListItem> items) async {
    double total = 0.0;
    // Mappa elementId -> {storeId, price, warning}
    Map<String, Map<String, dynamic>> itemDetails = {};

    final priceHistoryService = ref.read(priceHistoryProvider);

    for (var item in items) {
      final history = await priceHistoryService.getHistoryForProduct(item.productBarcode);
      
      bool isFresh = item.productBarcode.startsWith('2') && item.productBarcode.length == 7;
      
      if (widget.shoppingList.type == ShoppingListType.classic) {
        final targetStoreId = widget.shoppingList.storeId;
        final storePrices = history.where((h) => h.storeId == targetStoreId).toList();
        if (storePrices.isNotEmpty) {
           double price = isFresh 
               ? storePrices.map((h) => h.price).reduce((a, b) => a + b) / storePrices.length 
               : storePrices.first.price;
           total += price * item.quantity;
           itemDetails[item.id] = {'price': price, 'isAverage': isFresh};
        } else {
           itemDetails[item.id] = {'warning': 'Non venduto qui'};
        }
      } 
      else if (widget.shoppingList.type == ShoppingListType.mix) {
        final targetStoreId = item.storeId;
        final storePrices = history.where((h) => h.storeId == targetStoreId).toList();
        if (storePrices.isNotEmpty) {
           double price = isFresh 
               ? storePrices.map((h) => h.price).reduce((a, b) => a + b) / storePrices.length 
               : storePrices.first.price;
           total += price * item.quantity;
           itemDetails[item.id] = {'price': price, 'storeId': targetStoreId, 'isAverage': isFresh};
        } else {
           itemDetails[item.id] = {'warning': 'Prezzo non trovato'};
        }
      }
      else if (widget.shoppingList.type == ShoppingListType.superisparmio) {
        if (history.isEmpty) {
           itemDetails[item.id] = {'warning': 'Nessun prezzo registrato'};
        } else {
           Map<String, double> targetPricePerStore = {};
           
           if (isFresh) {
             // Calcola la media dei prezzi per ogni store
             Map<String, List<double>> pricesPerStore = {};
             for (var h in history) {
                pricesPerStore.putIfAbsent(h.storeId, () => []).add(h.price);
             }
             pricesPerStore.forEach((sId, prices) {
                targetPricePerStore[sId] = prices.reduce((a, b) => a + b) / prices.length;
             });
           } else {
             // Prezzo più recente per ogni store
             for (var h in history) {
               if (!targetPricePerStore.containsKey(h.storeId)) {
                 targetPricePerStore[h.storeId] = h.price;
               }
             }
           }
           
           String bestStoreId = targetPricePerStore.keys.first;
           double minPrice = targetPricePerStore[bestStoreId]!;
           
           targetPricePerStore.forEach((sId, price) {
             if (price < minPrice) {
               minPrice = price;
               bestStoreId = sId;
             }
           });
           
           total += minPrice * item.quantity;
           itemDetails[item.id] = {'price': minPrice, 'storeId': bestStoreId, 'isAverage': isFresh};
        }
      }
    }
    
    return {'total': total, 'details': itemDetails};
  }

  void _scanToAddProduct() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode != null && barcode is String) {
      String searchBarcode = barcode;
      if (barcode.length == 13 && barcode.startsWith('2')) {
        searchBarcode = barcode.substring(0, 7); // Estrai id radice per i banchi freschi
      }

      final products = ref.read(productProvider);
      final exists = products.any((p) => p.barcode == searchBarcode);
      
      if (!exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Prodotto non trovato. Aggiungilo prima dal catalogo.')),
          );
        }
        return;
      }

      String? storeIdForMix;
      
      if (widget.shoppingList.type == ShoppingListType.mix) {
        final history = await ref.read(priceHistoryProvider).getHistoryForProduct(searchBarcode);
        final availableStoreIds = history.map((h) => h.storeId).toSet();
        
        if (availableStoreIds.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nessun prezzo noto per questo prodotto in alcun supermercato.')),
            );
          }
          return;
        }

        final stores = ref.read(storeProvider).where((s) => availableStoreIds.contains(s.id)).toList();
        
        if (mounted) {
          storeIdForMix = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Scegli Supermercato (MIX)'),
              content: DropdownButtonFormField<String>(
                items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) => Navigator.pop(ctx, val),
              ),
            )
          );
        }
        if (storeIdForMix == null) return; // Cancellato dall'utente
      }

      final newItem = ShoppingListItem(
        id: const Uuid().v4(),
        listId: widget.shoppingList.id,
        productBarcode: searchBarcode,
        quantity: 1,
        storeId: storeIdForMix,
      );

      await ref.read(shoppingListItemServiceProvider).addItem(newItem);
    }
  }

  Widget _buildItemTile(ShoppingListItem item, Product product, Map<String, dynamic> details, List<Store> stores) {
    String subtitle = 'Quantità: ${item.quantity}';
    
    if (details.containsKey('warning')) {
      subtitle += ' - ⚠️ ${details['warning']}';
    } else if (details.containsKey('price')) {
      final isAvg = details['isAverage'] == true;
      subtitle += ' - €${details['price'].toStringAsFixed(2)} ${isAvg ? '(Stimato/Medio)' : 'cad.'}';
    }

    if (details.containsKey('storeId')) {
      final storeName = stores.firstWhere((s) => s.id == details['storeId'], orElse: () => Store(id: '', name: 'Ignoto')).name;
      subtitle += '\n📍 $storeName';
    } else if (widget.shoppingList.type == ShoppingListType.classic) {
      final storeName = stores.firstWhere((s) => s.id == widget.shoppingList.storeId, orElse: () => Store(id: '', name: 'Ignoto')).name;
      subtitle += '\n📍 $storeName (Fisso)';
    }

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Checkbox(
            value: item.isChecked,
            onChanged: (val) {
              ref.read(shoppingListItemServiceProvider).toggleItemCheck(item);
            },
          ),
          _buildProductImage(product),
        ],
      ),
      title: Text(product.name, style: TextStyle(
        decoration: item.isChecked ? TextDecoration.lineThrough : null,
      )),
      subtitle: Text(subtitle, style: TextStyle(
        color: details.containsKey('warning') ? Colors.orange : Colors.grey[700],
      )),
      isThreeLine: subtitle.contains('\n'),
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          ref.read(shoppingListItemServiceProvider).deleteItem(item);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsyncValue = ref.watch(shoppingListItemsProvider(widget.shoppingList.id));
    final products = ref.watch(productProvider);
    final stores = ref.watch(storeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.shoppingList.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanToAddProduct,
          ),
        ],
      ),
      body: itemsAsyncValue.when(
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('Nessun prodotto. Scansiona per aggiungere.'));
          }

          return FutureBuilder<Map<String, dynamic>>(
            future: _calculateTotalAndAssignments(items),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final total = snapshot.data!['total'] as double;
              final details = snapshot.data!['details'] as Map<String, Map<String, dynamic>>;

              // Raggruppamento per supeRisparmio
              if (widget.shoppingList.type == ShoppingListType.superisparmio) {
                // Group items by storeId
                Map<String, List<ShoppingListItem>> grouped = {};
                for (var item in items) {
                  final sId = details[item.id]?['storeId'] ?? 'unknown';
                  grouped.putIfAbsent(sId, () => []).add(item);
                }

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: grouped.keys.length,
                        itemBuilder: (context, index) {
                          final sId = grouped.keys.elementAt(index);
                          final storeItems = grouped[sId]!;
                          final storeName = sId == 'unknown' ? 'Da definire' : stores.firstWhere((s) => s.id == sId, orElse: () => Store(id: '', name: '')).name;
                          
                          return ExpansionTile(
                            initiallyExpanded: true,
                            title: Text('🛒 $storeName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                            children: storeItems.map((item) {
                              final product = products.firstWhere((p) => p.barcode == item.productBarcode, orElse: () => Product(barcode: 'Scconosciuto', name: 'Prodotto Ignoto'));
                              return _buildItemTile(item, product, details[item.id] ?? {}, stores);
                            }).toList(),
                          );
                        },
                      ),
                    ),
                    _buildTotalBar(total),
                  ],
                );
              }

              // Rendering Standard (Classic & Mix)
              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final product = products.firstWhere((p) => p.barcode == item.productBarcode, orElse: () => Product(barcode: 'Scconosciuto', name: 'Prodotto Ignoto'));
                        return _buildItemTile(item, product, details[item.id] ?? {}, stores);
                      },
                    ),
                  ),
                  _buildTotalBar(total),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
      ),
    );
  }

  Widget _buildTotalBar(double total) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.indigo.shade50,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Totale Previsto:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(
              '€${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage(Product product) {
    ImageProvider? image;
    if (product.imageUrl != null) {
      if (product.imageUrl!.startsWith('http')) {
        image = NetworkImage(product.imageUrl!);
      } else if (File(product.imageUrl!).existsSync()) {
        image = FileImage(File(product.imageUrl!));
      }
    }

    if (image != null) {
      return Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          image: DecorationImage(
            image: image,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.only(right: 8.0),
        child: Icon(Icons.inventory, color: Colors.grey),
      );
    }
  }
}
