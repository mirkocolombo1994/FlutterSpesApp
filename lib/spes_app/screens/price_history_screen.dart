import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/price_history.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';
import '../providers/price_history_provider.dart';

class PriceHistoryScreen extends ConsumerStatefulWidget {
  const PriceHistoryScreen({super.key});

  @override
  ConsumerState<PriceHistoryScreen> createState() => _PriceHistoryScreenState();
}

class _PriceHistoryScreenState extends ConsumerState<PriceHistoryScreen> {
  String? _selectedProductBarcode;
  String? _selectedStoreId;

  Widget _buildProductMode() {
    final products = ref.watch(productProvider);
    final stores = ref.watch(storeProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Seleziona Prodotto', border: OutlineInputBorder()),
            value: _selectedProductBarcode,
            items: products.map((p) => DropdownMenuItem(value: p.barcode, child: Text(p.name))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedProductBarcode = val;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedProductBarcode != null)
            Expanded(
              child: FutureBuilder<List<PriceHistory>>(
                future: ref.read(priceHistoryProvider).getHistoryForProduct(_selectedProductBarcode!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final history = snapshot.data!;
                  if (history.isEmpty) return const Center(child: Text('Nessuno storico prezzi trovato.'));

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Data', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Supermercato', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Prezzo', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: history.map((h) {
                          final date = DateTime.fromMillisecondsSinceEpoch(h.timestamp);
                          final store = stores.where((s) => s.id == h.storeId).firstOrNull;
                          final storeName = store?.name ?? 'Ignoto';
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(date))),
                            DataCell(Text(storeName)),
                            DataCell(Text('€${h.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoreMode() {
    final products = ref.watch(productProvider);
    final stores = ref.watch(storeProvider);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Seleziona Supermercato', border: OutlineInputBorder()),
            value: _selectedStoreId,
            items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedStoreId = val;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_selectedStoreId != null)
            Expanded(
              child: FutureBuilder<List<PriceHistory>>(
                future: ref.read(priceHistoryProvider).getHistoryForStore(_selectedStoreId!),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final history = snapshot.data!;
                  if (history.isEmpty) return const Center(child: Text('Nessuno storico prezzi trovato.'));

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Data', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Prodotto', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Prezzo', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: history.map((h) {
                          final date = DateTime.fromMillisecondsSinceEpoch(h.timestamp);
                          final product = products.where((p) => p.barcode == h.productBarcode).firstOrNull;
                          final productName = product?.name ?? 'Ignoto';
                          return DataRow(cells: [
                            DataCell(Text(DateFormat('dd/MM/yyyy HH:mm').format(date))),
                            DataCell(Text(productName)),
                            DataCell(Text('€${h.price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Storico Prezzi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Per Prodotto', icon: Icon(Icons.inventory_2)),
              Tab(text: 'Per Punto Vendita', icon: Icon(Icons.storefront)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildProductMode(),
            _buildStoreMode(),
          ],
        ),
      ),
    );
  }
}
