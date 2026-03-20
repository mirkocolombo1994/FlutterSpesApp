import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/price_history.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';
import '../providers/price_history_provider.dart';
import '../providers/category_provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'barcode_scanner_screen.dart';
import 'add_store_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Schermata per l'aggiunta o la modifica di un prodotto.
/// Include la scansione del codice a barre, il calcolo del prezzo al Kg,
/// la selezione dello store (con GPS o manuale) e il salvataggio nel database.
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
  String? _weightUnit = 'kg'; // Unità di misura predefinita
  String? _selectedStoreId;
  String? _promoType = 'Nessuna';
  DateTime? _promoValidUntil;
  final List<String> _promoTypes = ['Nessuna', 'Sconto %', 'Prezzo Tagliato', '1+1', '3x2', 'Altro'];

  File? _imageFile;
  String? _selectedCategory;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Listener per calcolare il prezzo al Kg in tempo reale
    _priceController.addListener(_calculatePricePerKg);
    _weightController.addListener(_calculatePricePerKg);
    
    if (widget.preselectedStoreId != null) {
      _selectedStoreId = widget.preselectedStoreId;
    }
    
    // Se la schermata viene aperta con un barcode già scansionato
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

  /// Calcola automaticamente il prezzo al Litro o al Kg in base al peso inserito
  void _calculatePricePerKg() {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (price != null && weight != null && weight > 0) {
      double calculatedPrice = 0.0;
      switch (_weightUnit) {
        case 'g':
        case 'ml':
          calculatedPrice = price / (weight / 1000); // Converte in Kg/L
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

  /// Elabora il codice a barre scansionato.
  /// Se è un prodotto fresco (codice che inizia per 2), estrae il prezzo direttamente dal barcode.
  /// Se il prodotto è già in archivio, popola automaticamente i campi.
  void _processScannedBarcode(String code) async {
    String searchBarcode = code;

    // Gestione Codici a Barre "Variabili" (es. prodotti pesati al banco fresco)
    // Solitamente iniziano con '2' e contengono il prezzo nelle ultime cifre
    if (code.length == 13 && code.startsWith('2')) {
      final baseBarcode = code.substring(0, 7); // Codice base del prodotto
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

    // Recupera lo storico prezzi per scoprire l'ultimo supermercato visitato per questo prodotto
    final history = await ref.read(priceHistoryProvider).getHistoryForProduct(searchBarcode);
    if (widget.preselectedStoreId != null) {
       // Ha già precedenza se passato come parametro
    } else if (history.isNotEmpty && mounted) {
      setState(() {
        _selectedStoreId = history.first.storeId; // Suggerisce l'ultimo store noto
      });
    }

    if (existingProduct != null) {
      // Prodotto già conosciuto: precompiliamo i campi
      _nameController.text = existingProduct.name;
      _brandController.text = existingProduct.brand ?? '';
      _description = existingProduct.description ?? '';
      _weightUnit = existingProduct.weightUnit ?? 'kg';
      _selectedCategory = existingProduct.category;

      if (existingProduct.imageUrl != null) {
          _imageFile = File(existingProduct.imageUrl!);
      }
      
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
      if (isFresh && mounted) {
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Prodotto Banco Fresco (Rilevato)';
        }
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

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<String?> _saveImageLocally(String barcode) async {
    if (_imageFile == null) return null;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = p.join(directory.path, 'product_images');
      await Directory(path).create(recursive: true);
      
      final fileName = '${barcode}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final localFile = await _imageFile!.copy(p.join(path, fileName));
      return localFile.path;
    } catch (e) {
      debugPrint('Errore nel salvataggio immagine: $e');
      return null;
    }
  }

  /// Salva il prodotto e la rilevazione prezzo nel database
  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedStoreId == null || _priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Seleziona il punto vendita in cui ti trovi e il prezzo!')),
        );
        return;
      }

      final priceValue = double.tryParse(_priceController.text.replaceAll(',', '.'));
      if (priceValue == null) return;

      // Genera codice manuale se assente
      String finalBarcode = _barcodeController.text;
      if (finalBarcode.isEmpty) {
        finalBarcode = 'MANUAL_${const Uuid().v4().substring(0, 8).toUpperCase()}';
      }

      // Salva l'immagine localmente prima di salvare il prodotto
      String? localImagePath = await _saveImageLocally(finalBarcode);

      final newProduct = Product(
        barcode: finalBarcode,
        name: _nameController.text,
        description: _description,
        brand: _brandController.text,
        weight: double.tryParse(_weightController.text.replaceAll(',', '.')),
        weightUnit: _weightUnit,
        pricePerKg: double.tryParse(_pricePerKgController.text),
        imageUrl: localImagePath ?? (File(_barcodeController.text).existsSync() ? _barcodeController.text : null),
        category: _selectedCategory,
      );

      // Salva nel DB Prodotti
      await ref.read(productProvider.notifier).addProduct(newProduct);

      // Salva record dello storico prezzi
      int? expirationTimestamp = _promoValidUntil?.millisecondsSinceEpoch;
      String? cleanPromoType = _promoType == 'Nessuna' ? null : _promoType;
      if (cleanPromoType == 'Sconto %' && _discountPercentController.text.isNotEmpty) {
        cleanPromoType = 'Sconto ${_discountPercentController.text}%';
      }

      final prHistory = PriceHistory(
        id: const Uuid().v4(),
        productBarcode: finalBarcode,
        storeId: _selectedStoreId!,
        price: priceValue,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        promoType: cleanPromoType,
        promoValidUntil: expirationTimestamp,
      );
      await ref.read(priceHistoryProvider).addPriceHistory(prHistory);

      if (mounted) Navigator.pop(context, finalBarcode);
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
                      labelText: 'Codice a Barre (Opzionale)',
                      border: OutlineInputBorder(),
                      helperText: 'Lascia vuoto per inserimento manuale',
                    ),
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
            // Sezione Foto del Prodotto
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.indigo,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        onPressed: () => _pickImage(ImageSource.camera),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.blueGrey,
                      radius: 20,
                      child: IconButton(
                        icon: const Icon(Icons.photo_library, color: Colors.white, size: 20),
                        onPressed: () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ),
                ],
              ),
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
            // Selezione della Categoria tramite Dropdown sincronizzato
            Consumer(
              builder: (context, ref, child) {
                final categories = ref.watch(categoryProvider);
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    border: OutlineInputBorder(),
                  ),
                  value: categories.any((c) => c.name == _selectedCategory) ? _selectedCategory : null,
                  items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                  hint: const Text('Seleziona categoria'),
                );
              },
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
                labelText: 'Prezzo al Kg/L (€) (Auto)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              readOnly: true, // Campo calcolato automaticamente
            ),
            const SizedBox(height: 16),
            // Selezione del Punto Vendita
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
            // Gestione Promozioni
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
                  : 'Fino al: ${DateFormat('dd/MM/yyyy').format(_promoValidUntil!)}'),
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
