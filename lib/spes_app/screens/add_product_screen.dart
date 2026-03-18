import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/price_history.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';
import '../providers/price_history_provider.dart';
import 'package:uuid/uuid.dart';
import 'barcode_scanner_screen.dart';
import 'add_store_screen.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers per aggiornare dinamicamente l'UI quando si scansiona un codice fresco
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _pricePerKgController = TextEditingController();

  String _description = '';
  String? _weightUnit = 'kg'; // Default unit
  String? _selectedStoreId;

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _pricePerKgController.dispose();
    super.dispose();
  }

  void _processScannedBarcode(String code) {
    // Logica per i codici a barre a peso variabile (Ortofrutta, Gastronomia, Carne).
    if (code.length == 13 && code.startsWith('2')) {
      final baseBarcode = code.substring(0, 7); // Manteniamo solo il codice prodotto
      final priceDigits = code.substring(7, 12);
      final parsedPrice = double.tryParse(priceDigits);

      _barcodeController.text = baseBarcode;

      if (parsedPrice != null && parsedPrice > 0) {
        final priceInEuros = parsedPrice / 100.0;
        _priceController.text = priceInEuros.toStringAsFixed(2);
      }

      final products = ref.read(productProvider);
      final existingProduct = products.where((p) => p.barcode == baseBarcode).firstOrNull;

      if (existingProduct != null) {
        _nameController.text = existingProduct.name;
        _brandController.text = existingProduct.brand ?? '';
        _description = existingProduct.description ?? '';
        _weightUnit = existingProduct.weightUnit ?? 'kg';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🏷️ Prodotto fresco riconosciuto: ${existingProduct.name}! Prezzo estratto: €${_priceController.text}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Prodotto Banco Fresco (Rilevato)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏷️ Nuovo prodotto fresco! Memorizzalo con questo nome. Prezzo estratto automaticamente!'),
            backgroundColor: Colors.indigo,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } else {
      _barcodeController.text = code;
      
      final products = ref.read(productProvider);
      final existingProduct = products.where((p) => p.barcode == code).firstOrNull;

      if (existingProduct != null) {
        _nameController.text = existingProduct.name;
        _brandController.text = existingProduct.brand ?? '';
        _description = existingProduct.description ?? '';
        _weightUnit = existingProduct.weightUnit ?? 'kg';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📦 Prodotto riconosciuto in archivio: ${existingProduct.name}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedStoreId == null || _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona il punto vendita in cui ti trovi e il prezzo!')),
        );
        return;
      }

      final priceValue = double.tryParse(_priceController.text);
      if (priceValue == null) return;

      final newProduct = Product(
        barcode: _barcodeController.text,
        name: _nameController.text,
        description: _description,
        brand: _brandController.text,
        weight: double.tryParse(_weightController.text),
        weightUnit: _weightUnit,
        pricePerKg: double.tryParse(_pricePerKgController.text),
      );

      // Salva nel DB Prodotti
      await ref.read(productProvider.notifier).addProduct(newProduct);

      // Salva record dello storico
      final prHistory = PriceHistory(
        id: const Uuid().v4(),
        productBarcode: _barcodeController.text,
        storeId: _selectedStoreId!,
        price: priceValue,
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
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      labelText: 'Codice a Barre *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Inserisci codice' : null,
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
                      _processScannedBarcode(scannedCode);
                    }
                  },
                )
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Inserisci nome' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _brandController,
              decoration: const InputDecoration(
                labelText: 'Marca',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    decoration: const InputDecoration(
                      labelText: 'Peso / Quantità',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
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
            TextFormField(
              controller: _pricePerKgController,
              decoration: const InputDecoration(
                labelText: 'Prezzo al Kg (€) (Opzionale)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                    onPressed: () async {
                      final newStoreId = await Navigator.push<String>(
                        context,
                        MaterialPageRoute(builder: (context) => const AddStoreScreen()),
                      );
                      if (newStoreId != null) {
                        setState(() {
                          _selectedStoreId = newStoreId;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
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
            ),
          ],
        ),
      ),
    );
  }
}
