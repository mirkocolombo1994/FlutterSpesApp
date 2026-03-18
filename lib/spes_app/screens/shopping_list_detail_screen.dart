import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      
      if (widget.shoppingList.type == ShoppingListType.classic) {
        final targetStoreId = widget.shoppingList.storeId;
        final storePrices = history.where((h) => h.storeId == targetStoreId).toList();
        if (storePrices.isNotEmpty) {
           double price = storePrices.first.price;
           total += price * item.quantity;
           itemDetails[item.id] = {'price': price};
        } else {
           itemDetails[item.id] = {'warning': 'Non venduto qui'};
        }
      } 
      else if (widget.shoppingList.type == ShoppingListType.mix) {
        final targetStoreId = item.storeId;
        final storePrices = history.where((h) => h.storeId == targetStoreId).toList();
        if (storePrices.isNotEmpty) {
           double price = storePrices.first.price;
           total += price * item.quantity;
           itemDetails[item.id] = {'price': price, 'storeId': targetStoreId};
        } else {
           itemDetails[item.id] = {'warning': 'Prezzo non trovato'};
        }
      }
      else if (widget.shoppingList.type == ShoppingListType.superisparmio) {
        if (history.isEmpty) {
           itemDetails[item.id] = {'warning': 'Nessun prezzo registrato'};
        } else {
           // Trova il prezzo minimo tra i vari store
           Map<String, double> latestPricePerStore = {};
           for (var h in history) {
             if (!latestPricePerStore.containsKey(h.storeId)) {
               latestPricePerStore[h.storeId] = h.price;
             }
           }
           
           String bestStoreId = latestPricePerStore.keys.first;
           double minPrice = latestPricePerStore[bestStoreId]!;
           
           latestPricePerStore.forEach((sId, price) {
             if (price < minPrice) {
               minPrice = price;
               bestStoreId = sId;
             }
           });
           
           total += minPrice * item.quantity;
           itemDetails[item.id] = {'price': minPrice, 'storeId': bestStoreId};
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
      final products = ref.read(productProvider);
      final exists = products.any((p) => p.barcode == barcode);
      
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
        final history = await ref.read(priceHistoryProvider).getHistoryForProduct(barcode);
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
        productBarcode: barcode,
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
      subtitle += ' - €${details['price'].toStringAsFixed(2)} cad.';
    }

    if (details.containsKey('storeId')) {
      final storeName = stores.firstWhere((s) => s.id == details['storeId'], orElse: () => Store(id: '', name: 'Ignoto')).name;
      subtitle += '\n📍 $storeName';
    } else if (widget.shoppingList.type == ShoppingListType.classic) {
      final storeName = stores.firstWhere((s) => s.id == widget.shoppingList.storeId, orElse: () => Store(id: '', name: 'Ignoto')).name;
      subtitle += '\n📍 $storeName (Fisso)';
    }

    return ListTile(
      leading: Checkbox(
        value: item.isChecked,
        onChanged: (val) {
          ref.read(shoppingListItemServiceProvider).toggleItemCheck(item);
        },
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
}
