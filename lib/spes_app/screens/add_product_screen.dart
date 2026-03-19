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
  final String? initialBarcode;
  final String? preselectedStoreId;

  const AddProductScreen({super.key, this.initialBarcode, this.preselectedStoreId});

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
  final _discountPercentController = TextEditingController();

  String _description = '';
  String? _weightUnit = 'kg'; // Default unit
  String? _selectedStoreId;
  String? _promoType = 'Nessuna';
  DateTime? _promoValidUntil;
  final List<String> _promoTypes = ['Nessuna', 'Sconto %', 'Prezzo Tagliato', '1+1', '3x2', 'Altro'];

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_calculatePricePerKg);
    _weightController.addListener(_calculatePricePerKg);
    if (widget.preselectedStoreId != null) {
      _selectedStoreId = widget.preselectedStoreId;
    }
    if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processScannedBarcode(widget.initialBarcode!);
      });
    }
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _weightController.dispose();
    _priceController.dispose();
    _pricePerKgController.dispose();
    _discountPercentController.dispose();
    super.dispose();
  }

  void _calculatePricePerKg() {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (price != null && weight != null && weight > 0) {
      double calculatedPrice = 0.0;
      switch (_weightUnit) {
        case 'g':
        case 'ml':
          calculatedPrice = price / (weight / 1000);
          break;
        case 'kg':
        case 'l':
        case 'pz':
          calculatedPrice = price / weight;
          break;
      }
      _pricePerKgController.text = calculatedPrice.toStringAsFixed(2);
    } else {
      _pricePerKgController.text = '';
    }
  }

  void _processScannedBarcode(String code) async {
    String searchBarcode = code;

    if (code.length == 13 && code.startsWith('2')) {
      final baseBarcode = code.substring(0, 7);
      searchBarcode = baseBarcode;
      final priceDigits = code.substring(7, 12);
      final parsedPrice = double.tryParse(priceDigits);

      _barcodeController.text = baseBarcode;

      if (parsedPrice != null && parsedPrice > 0) {
        final priceInEuros = parsedPrice / 100.0;
        _priceController.text = priceInEuros.toStringAsFixed(2);
      }
    } else {
      _barcodeController.text = code;
    }

    final products = ref.read(productProvider);
    final existingProduct = products.where((p) => p.barcode == searchBarcode).firstOrNull;

    // Recupera lo storico prezzi per scoprire l'ultimo supermercato
    final history = await ref.read(priceHistoryProvider).getHistoryForProduct(searchBarcode);
    if (widget.preselectedStoreId != null) {
       // Ha già precedenza perché impostato in initState
    } else if (history.isNotEmpty && mounted) {
      setState(() {
        _selectedStoreId = history.first.storeId;
      });
    }

    if (existingProduct != null) {
      _nameController.text = existingProduct.name;
      _brandController.text = existingProduct.brand ?? '';
      _description = existingProduct.description ?? '';
      _weightUnit = existingProduct.weightUnit ?? 'kg';
      
      bool isFresh = searchBarcode.length == 7 && searchBarcode.startsWith('2');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFresh 
                ? '🏷️ Fresco riconosciuto: ${existingProduct.name}. Supermercato auto-impostato!' 
                : '📦 Prodotto in archivio: ${existingProduct.name}. Supermercato auto-impostato!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else {
      bool isFresh = searchBarcode.length == 7 && searchBarcode.startsWith('2');
      if (isFresh) {
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Prodotto Banco Fresco (Rilevato)';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🏷️ Nuovo prodotto fresco! Memorizzalo. Prezzo estratto!'),
              backgroundColor: Colors.indigo,
              duration: Duration(seconds: 4),
            ),
          );
        }
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
      int? expirationTimestamp = _promoValidUntil?.millisecondsSinceEpoch;
      String? cleanPromoType = _promoType == 'Nessuna' ? null : _promoType;
      if (cleanPromoType == 'Sconto %' && _discountPercentController.text.isNotEmpty) {
        cleanPromoType = 'Sconto ${_discountPercentController.text}%';
      }

      final prHistory = PriceHistory(
        id: const Uuid().v4(),
        productBarcode: _barcodeController.text,
        storeId: _selectedStoreId!,
        price: priceValue,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        promoType: cleanPromoType,
        promoValidUntil: expirationTimestamp,
      );
      await ref.read(priceHistoryProvider).addPriceHistory(prHistory);

      if (mounted) Navigator.pop(context, _barcodeController.text);
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
                    _calculatePricePerKg();
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
                if (double.tryParse(value.replaceAll(',', '.')) == null) return 'Prezzo non valido';
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Promozione',
                border: OutlineInputBorder(),
              ),
              value: _promoType,
              items: _promoTypes.map((pt) => DropdownMenuItem(value: pt, child: Text(pt))).toList(),
              onChanged: (val) {
                setState(() {
                  _promoType = val;
                });
              },
            ),
            if (_promoType == 'Sconto %') ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _discountPercentController,
                decoration: const InputDecoration(
                  labelText: 'Percentuale Sconto (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
            if (_promoType != null && _promoType != 'Nessuna') ...[
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_promoValidUntil == null 
                  ? 'Nessuna Scadenza Selezionata' 
                  : 'Fino al: ${_promoValidUntil!.day.toString().padLeft(2, '0')}/${_promoValidUntil!.month.toString().padLeft(2, '0')}/${_promoValidUntil!.year}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_promoValidUntil != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          setState(() {
                            _promoValidUntil = null;
                          });
                        }
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context, 
                          initialDate: DateTime.now(), 
                          firstDate: DateTime.now(), 
                          lastDate: DateTime.now().add(const Duration(days: 365))
                        );
                        if (date != null) {
                          setState(() {
                            _promoValidUntil = date;
                          });
                        }
                      }
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
