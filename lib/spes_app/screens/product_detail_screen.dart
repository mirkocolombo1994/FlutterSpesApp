import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/price_history.dart';
import '../models/store.dart';
import '../providers/product_provider.dart';
import '../providers/price_history_provider.dart';
import '../providers/store_provider.dart';
import '../providers/category_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _categoryController;
  late TextEditingController _brandController;
  
  List<PriceHistory> _history = [];
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _categoryController = TextEditingController(text: widget.product.category ?? '');
    _brandController = TextEditingController(text: widget.product.brand ?? '');
    _loadPriceHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _loadPriceHistory() async {
    final history = await ref.read(priceHistoryProvider).getHistoryForProduct(widget.product.barcode);
    if (mounted) {
      setState(() {
        _history = history;
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    final updatedProduct = Product(
      barcode: widget.product.barcode,
      name: _nameController.text.trim(),
      description: widget.product.description,
      brand: _brandController.text.trim(),
      weight: widget.product.weight,
      weightUnit: widget.product.weightUnit,
      imageUrl: widget.product.imageUrl,
      category: _categoryController.text.trim().isEmpty ? null : _categoryController.text.trim(),
      pricePerKg: widget.product.pricePerKg,
    );

    await ref.read(productProvider.notifier).updateProduct(updatedProduct);
    
    if (mounted) {
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Prodotto aggiornato con successo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the product list to get the most updated version of THIS product
    final products = ref.watch(productProvider);
    final product = products.firstWhere(
      (p) => p.barcode == widget.product.barcode,
      orElse: () => widget.product,
    );

    // Watch stores for mapping names in the table
    final stores = ref.watch(storeProvider);
    
    // Group history by store to get latest price
    final latestPrices = <String, PriceHistory>{};
    for (var h in _history) {
      if (!latestPrices.containsKey(h.storeId)) {
        latestPrices[h.storeId] = h;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: _isEditing ? const Text('Modifica Prodotto') : Text(product.name),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _nameController.text = product.name;
                  _categoryController.text = product.category ?? '';
                  _brandController.text = product.brand ?? '';
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveChanges,
            ),
          ]
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Image Header
            _buildImageHeader(product),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMainInfo(product),
                  const SizedBox(height: 24),
                  
                  // Product Info Section
                  _buildDetailsSection(product),
                  
                  const SizedBox(height: 32),
                  
                  // Price History Table Section
                  _buildPriceHistoryTable(latestPrices, stores),
                  
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSectionHeader('Descrizione'),
                    const SizedBox(height: 8),
                    Text(
                      product.description!,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.blueGrey.shade800,
                            height: 1.5,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageHeader(Product product) {
    if (product.imageUrl != null && File(product.imageUrl!).existsSync()) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: FileImage(File(product.imageUrl!)),
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: 150,
        color: Colors.blueGrey.shade50,
        child: const Icon(Icons.inventory, size: 80, color: Colors.blueGrey),
      );
    }
  }

  Widget _buildMainInfo(Product product) {
    if (_isEditing) {
      final categories = ref.watch(categoryProvider);
      
      return Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nome Prodotto', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: categories.any((c) => c.name == _categoryController.text) 
                ? _categoryController.text 
                : null,
            decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
            items: categories.map((c) {
              return DropdownMenuItem(value: c.name, child: Text(c.name));
            }).toList(),
            onChanged: (val) {
              if (val != null) _categoryController.text = val;
            },
            hint: const Text('Seleziona categoria'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _brandController,
            decoration: const InputDecoration(labelText: 'Marca', border: OutlineInputBorder()),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade900,
                    ),
              ),
              if (product.brand != null && product.brand!.isNotEmpty)
                Text(
                  product.brand!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.blueGrey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
            ],
          ),
        ),
        if (product.category != null)
          Chip(
            label: Text(product.category!),
            backgroundColor: Colors.blueGrey.shade100,
            labelStyle: const TextStyle(color: Colors.blueGrey, fontSize: 12),
          ),
      ],
    );
  }

  Widget _buildDetailsSection(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Dettagli Tecnici'),
        _buildInfoRow(Icons.qr_code_scanner, 'Barcode', product.barcode),
        if (product.weight != null)
          _buildInfoRow(
            Icons.scale,
            'Formato',
            '${product.weight} ${product.weightUnit ?? ""}',
          ),
      ],
    );
  }

  Widget _buildPriceHistoryTable(Map<String, PriceHistory> latestPrices, List<Store> stores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Ultimi Prezzi Rilevati'),
        const SizedBox(height: 8),
        if (_isLoadingHistory)
          const Center(child: CircularProgressIndicator())
        else if (latestPrices.isEmpty)
          const Text('Nessuna rilevazione prezzo disponibile.')
        else
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey.shade100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FixedColumnWidth(80),
                2: FixedColumnWidth(100),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blueGrey.shade50),
                  children: [
                    _buildTableCell('Supermercato', isHeader: true),
                    _buildTableCell('Prezzo', isHeader: true),
                    _buildTableCell('Data', isHeader: true),
                  ],
                ),
                ...latestPrices.entries.map((entry) {
                  final storeId = entry.key;
                  final history = entry.value;
                  final store = stores.where((s) => s.id == storeId).firstOrNull;
                  final date = DateTime.fromMillisecondsSinceEpoch(history.timestamp);
                  
                  return TableRow(
                    children: [
                      _buildTableCell(store?.name ?? 'Sconosciuto'),
                      _buildTableCell('${history.price.toStringAsFixed(2)} €'),
                      _buildTableCell(DateFormat('dd/MM/yyyy').format(date)),
                    ],
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade400,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blueGrey.shade700),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade500)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }
}
