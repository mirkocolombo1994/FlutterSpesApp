import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/price_history.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';
import '../providers/price_history_provider.dart';
import 'package:uuid/uuid.dart';
// TODO: Import mobile_scanner for barcode scanning
import 'barcode_scanner_screen.dart';
import 'add_store_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  String _barcode = '';
  String _name = '';
  String _description = '';
  String _brand = '';
  double? _weight;
  String? _weightUnit = 'kg'; // Default unit
  double? _price;
  String? _selectedStoreId;

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Ensure store is selected and price is provided.
      // Since a product is typically added standing inside a store checking its price.
      if (_selectedStoreId == null || _price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona il punto vendita in cui ti trovi e il prezzo!')),
        );
        return;
      }

      final newProduct = Product(
        barcode: _barcode,
        name: _name,
        description: _description,
        brand: _brand,
        weight: _weight,
        weightUnit: _weightUnit,
      );

      // Save product to DB
      await ref.read(productProvider.notifier).addProduct(newProduct);

      // Save initial price history record
      final prHistory = PriceHistory(
        id: const Uuid().v4(),
        productBarcode: _barcode,
        storeId: _selectedStoreId!,
        price: _price!,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await ref.read(priceHistoryProvider).addPriceHistory(prHistory);

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Prodotto'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProduct,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _barcode),
                    decoration: const InputDecoration(
                      labelText: 'Codice a Barre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Inserisci codice' : null,
                    onChanged: (value) => _barcode = value,
                    onSaved: (value) => _barcode = value!,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.qr_code_scanner, size: 40),
                  onPressed: () async {
                    final String? scannedCode = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
                    );
                    if (scannedCode != null) {
                      setState(() {
                        _barcode = scannedCode;
                      });
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Inserisci nome' : null,
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _brand = value ?? '',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Peso / Quantità',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) => _weight = double.tryParse(value ?? ''),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _weightUnit,
                  items: ['kg', 'g', 'l', 'ml', 'pz'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _weightUnit = newValue;
                    });
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'In quale punto vendita ti trovi?',
                      border: OutlineInputBorder(),
                    ),
                    value: stores.any((s) => s.id == _selectedStoreId) ? _selectedStoreId : null,
                    items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedStoreId = value;
                      });
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: IconButton(
                    icon: const Icon(Icons.add_business, size: 36, color: Colors.indigo),
                    tooltip: 'Aggiungi nuovo punto vendita',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddStoreScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Prezzo rilevato (€) *',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Inserisci prezzo';
                if (double.tryParse(value) == null) return 'Prezzo non valido';
                return null;
              },
              onSaved: (value) => _price = double.tryParse(value!),
            ),
          ],
        ),
      ),
    );
  }
}
