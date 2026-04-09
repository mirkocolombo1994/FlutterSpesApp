import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/price_history.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';
import '../providers/price_history_provider.dart';
import '../providers/category_provider.dart';
import '../providers/promotion_provider.dart';
import '../models/promotion.dart';
import '../services/spes_app_database_helper.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'barcode_scanner_screen.dart';
import 'add_store_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../constants/app_strings.dart';
import '../providers/open_food_facts_provider.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  final String? initialBarcode;
  final String? preselectedStoreId;
  final bool isFastMode;

  const AddProductScreen({
    super.key, 
    this.initialBarcode, 
    this.preselectedStoreId,
    this.isFastMode = false,
  });

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _barcodeController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();
  final _pricePerKgController = TextEditingController();
  final _discountPercentController = TextEditingController();
  final _priceFocusNode = FocusNode();

  String _description = '';
  String? _weightUnit = AppStrings.unitKg;
  String? _selectedStoreId;
  String? _promoType = AppStrings.promoNone;
  DateTime? _promoValidUntil;
  final List<String> _promoTypes = [
    AppStrings.promoNone,
    AppStrings.promoDiscountPercent,
    AppStrings.promoCutPrice,
    AppStrings.promo1plus1,
    AppStrings.promo3x2,
    AppStrings.promoOther
  ];

  File? _imageFile;
  String? _remoteImageUrl; // Per le immagini da Open Food Facts
  String? _selectedCategory;
  String? _rawOffData; // Memorizziamo i dati OFF per salvarli nel DB

  final ImagePicker _picker = ImagePicker();

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
    _priceFocusNode.dispose();
    super.dispose();
  }

  void _calculatePricePerKg() {
    final price = double.tryParse(_priceController.text.replaceAll(',', '.'));
    final weight = double.tryParse(_weightController.text.replaceAll(',', '.'));
    if (price != null && weight != null && weight > 0) {
      double calculatedPrice = 0.0;
      switch (_weightUnit) {
        case AppStrings.unitG:
        case AppStrings.unitMl:
          calculatedPrice = price / (weight / 1000);
          break;
        case AppStrings.unitKg:
        case AppStrings.unitL:
        case AppStrings.unitPz:
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

    final history = await ref.read(priceHistoryProvider).getHistoryForProduct(searchBarcode);
    if (widget.preselectedStoreId != null) {
      // Già impostato in initState
    } else if (history.isNotEmpty && mounted) {
      final stores = ref.read(storeProvider);
      // Cerchiamo il primo record nello storico che faccia riferimento a un supermercato ancora esistente
      final validHistory = history.where((h) => stores.any((s) => s.id == h.storeId)).firstOrNull;
      
      if (validHistory != null) {
        setState(() {
          _selectedStoreId = validHistory.storeId;
        });
      }
    }

    if (existingProduct != null) {
      _nameController.text = existingProduct.name;
      _brandController.text = existingProduct.brand ?? '';
      _description = existingProduct.description ?? '';
      _weightUnit = existingProduct.weightUnit ?? AppStrings.unitKg;
      
      // We check if the existing category is a Name or an ID.
      // If it's a name that matches any category ID, we convert it (soft migration).
      _selectedCategory = existingProduct.category;

      if (existingProduct.imageUrl != null) {
        if (existingProduct.imageUrl!.startsWith('http')) {
          _remoteImageUrl = existingProduct.imageUrl;
          _imageFile = null;
        } else {
          _imageFile = File(existingProduct.imageUrl!);
          _remoteImageUrl = null;
        }
      }
      
      bool isFresh = searchBarcode.length == 7 && searchBarcode.startsWith('2');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isFresh 
                ? '${AppStrings.freshProductDetected}${existingProduct.name}${AppStrings.autoSetStore}' 
                : '${AppStrings.productInArchive}${existingProduct.name}${AppStrings.autoSetStore}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        _priceFocusNode.requestFocus();
      }
    } else {
      bool isFresh = searchBarcode.length == 7 && searchBarcode.startsWith('2');
      
      if (!isFresh) {
        // Mostriamo un caricamento rapido
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ricerca su Open Food Facts...'),
              duration: Duration(seconds: 1),
            ),
          );
        }

        final offService = ref.read(openFoodFactsProvider);
        final offProduct = await offService.fetchProductByBarcode(searchBarcode);

        if (offProduct != null && mounted) {
          setState(() {
            _nameController.text = offProduct.name;
            _brandController.text = offProduct.brand ?? '';
            _description = offProduct.description ?? '';
            _weightUnit = offProduct.weightUnit ?? AppStrings.unitKg;
            if (offProduct.weight != null) {
              _weightController.text = offProduct.weight!.toString();
            }
            
            // Gestione Categoria
            if (offProduct.category != null) {
              final String categoryId = offProduct.category!;
              final categories = ref.read(categoryProvider);
              
              if (!categories.any((c) => c.id == categoryId)) {
                // Se la categoria non esiste, la creiamo con un nome pulito
                final offService = ref.read(openFoodFactsProvider);
                final Category newCat = Category(
                  id: categoryId,
                  name: offService.cleanCategoryName(categoryId),
                );
                ref.read(categoryProvider.notifier).addCategory(newCat);
              }
              _selectedCategory = categoryId;
            }
            
            _remoteImageUrl = offProduct.imageUrl;
            _rawOffData = offProduct.rawOffData;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Prodotto trovato su Open Food Facts: ${offProduct.name}'),
              backgroundColor: Colors.blue,
            ),
          );
          _priceFocusNode.requestFocus();
          return; // Usciamo perché abbiamo trovato il prodotto
        }
      }

      if (isFresh && mounted) {
        if (_nameController.text.isEmpty) {
          _nameController.text = 'Prodotto Banco Fresco (Rilevato)';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.newFreshProductAlert),
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
        _remoteImageUrl = null; // L'immagine locale vince su quella remota
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

  void _saveProduct() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final stores = ref.read(storeProvider);

      // [FIX] Il punto vendita e il prezzo sono obbligatori se siamo in modalità spesa (FastMode) o se abbiamo iniziato a inserire un prezzo
      bool isPriceEntered = _priceController.text.isNotEmpty;
      bool mustHaveStore = widget.isFastMode || widget.preselectedStoreId != null || isPriceEntered;
      
      if (mustHaveStore) {
        if (_selectedStoreId == null || !stores.any((s) => s.id == _selectedStoreId)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.validationStoreRequired)),
          );
          return;
        }
        if (_priceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(AppStrings.priceRequiredValidator)),
          );
          return;
        }
      }

      final priceValue = double.tryParse(_priceController.text.replaceAll(',', '.'));

      String finalBarcode = _barcodeController.text;
      if (finalBarcode.isEmpty) {
        finalBarcode = 'MANUAL_${const Uuid().v4().substring(0, 8).toUpperCase()}';
      }

      String? localImagePath = await _saveImageLocally(finalBarcode);

      final newProduct = Product(
        barcode: finalBarcode,
        name: _nameController.text,
        description: _description,
        brand: _brandController.text,
        weight: double.tryParse(_weightController.text.replaceAll(',', '.')),
        weightUnit: _weightUnit,
        pricePerKg: double.tryParse(_pricePerKgController.text),
        imageUrl: localImagePath ?? _remoteImageUrl ?? (File(_barcodeController.text).existsSync() ? _barcodeController.text : null),
        category: _selectedCategory,
        rawOffData: _rawOffData,
      );

      await ref.read(productProvider.notifier).addProduct(newProduct);

      // [FIX] Validazione dello store_id per evitare crash FOREIGN KEY se il supermercato è stato eliminato
      final bool isStoreValid = stores.any((s) => s.id == _selectedStoreId);

      // Salviamo lo storico solo se abbiamo impostato prezzo e store (e lo store è ancora valido)
      if (_selectedStoreId != null && priceValue != null && isStoreValid) {
        int? expirationTimestamp = _promoValidUntil?.millisecondsSinceEpoch;
        String? cleanPromoType = _promoType == AppStrings.promoNone ? null : _promoType;
        if (cleanPromoType == AppStrings.promoDiscountPercent && _discountPercentController.text.isNotEmpty) {
          cleanPromoType = 'Sconto ${_discountPercentController.text}%';
        }

        // [FIX: Prevenzione Duplicati Promozioni]
        // Verifichiamo se esiste già una promozione diversa per questo prodotto nello stesso negozio
        final existingHistory = await ref.read(priceHistoryProvider).getHistoryForProduct(finalBarcode);
        final storeHistory = existingHistory.where((h) => h.storeId == _selectedStoreId).firstOrNull;
        
        if (storeHistory != null && storeHistory.promoType != null && storeHistory.promoType != cleanPromoType) {
          if (mounted) {
            final bool? confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Attenzione: Promozione esistente'),
                content: Text('In questo punto vendita esiste già una promozione di tipo "${storeHistory.promoType}". Vuoi sostituirla con "$cleanPromoType"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true), 
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text('Sostituisci'),
                  ),
                ],
              ),
            );

            if (confirmed != true) return; // L'utente ha annullato il salvataggio
          }
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

        // [NUOVO] Creazione automatica Promozione e Linking
        if (cleanPromoType != null) {
          final promos = ref.read(promotionProvider);
          final existingPromo = promos.where((p) => p.storeId == _selectedStoreId && p.name == cleanPromoType).firstOrNull;
          
          String promoIdToLink;
          if (existingPromo == null) {
             promoIdToLink = const Uuid().v4();
             final newPromo = Promotion(
               id: promoIdToLink,
               name: cleanPromoType,
               storeId: _selectedStoreId!,
               discountPercentage: _promoType == AppStrings.promoDiscountPercent ? (double.tryParse(_discountPercentController.text) ?? 0.0) : 0.0,
               validFrom: DateTime.now(),
               validUntil: _promoValidUntil ?? DateTime.now().add(const Duration(days: 30)), // Fallback 30gg
             );
             await ref.read(promotionProvider.notifier).addPromotion(newPromo);
          } else {
             promoIdToLink = existingPromo.id;
          }
          await SpesAppDatabaseHelper.instance.linkProductToPromotion(promoIdToLink, finalBarcode);
        }
      }

      if (mounted) Navigator.pop(context, finalBarcode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newProduct),
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
            // SEZIONE 1: DATI PRODOTTO
            _buildSectionHeader(AppStrings.productDataSection, Icons.inventory),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (!widget.isFastMode) ...[
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _barcodeController,
                              decoration: const InputDecoration(
                                labelText: AppStrings.barcodeOptional,
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.qr_code_scanner, size: 36),
                            onPressed: () async {
                              final String? scannedCode = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
                              );
                              if (scannedCode != null) _processScannedBarcode(scannedCode);
                            },
                          )
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Foto
                    if (!widget.isFastMode) ...[
                      Center(
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                                child: _imageFile != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                                      )
                                    : (_remoteImageUrl != null
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: Image.network(_remoteImageUrl!, fit: BoxFit.cover, errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 40)),
                                          )
                                        : const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)),
                            ),
                            Positioned(bottom: 0, right: 0, child: _buildImageAction(Icons.camera_alt, () => _pickImage(ImageSource.camera))),
                            Positioned(bottom: 0, left: 0, child: _buildImageAction(Icons.photo_library, () => _pickImage(ImageSource.gallery))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: AppStrings.productNameRequired, border: OutlineInputBorder()),
                      validator: (value) => value == null || value.isEmpty ? AppStrings.productNameValidator : null,
                    ),
                    const SizedBox(height: 16),
                    if (!widget.isFastMode) ...[
                      Consumer(builder: (context, ref, child) {
                        final categories = ref.watch(categoryProvider);
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: AppStrings.categoryLabel, border: OutlineInputBorder()),
                          // We check by ID now
                          value: categories.any((c) => c.id == _selectedCategory) ? _selectedCategory : null,
                          items: categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                          onChanged: (val) => setState(() => _selectedCategory = val),
                          hint: const Text(AppStrings.selectCategoryHint),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _brandController,
                      decoration: const InputDecoration(labelText: AppStrings.brandLabel, border: OutlineInputBorder()),
                    ),
                    if (!widget.isFastMode) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(labelText: AppStrings.weightQuantity, border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: _weightUnit,
                            items: [AppStrings.unitKg, AppStrings.unitG, AppStrings.unitL, AppStrings.unitMl, AppStrings.unitPz]
                                .map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                            onChanged: (val) {
                              setState(() => _weightUnit = val);
                              _calculatePricePerKg();
                            },
                          )
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.isFastMode) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('Rilevazione Prezzo', Icons.payments_outlined),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      if (_selectedStoreId == null) ...[
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: AppStrings.storeSelectionPrompt, border: OutlineInputBorder()),
                          value: stores.any((s) => s.id == _selectedStoreId) ? _selectedStoreId : null,
                          items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (val) => setState(() => _selectedStoreId = val),
                          validator: (value) => value == null ? AppStrings.validationStoreRequired : null,
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _priceController,
                        focusNode: _priceFocusNode,
                        decoration: const InputDecoration(labelText: AppStrings.recordedPriceRequired, border: OutlineInputBorder()),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Prezzo in Promozione?'),
                        value: _promoType != AppStrings.promoNone,
                        onChanged: (val) {
                          setState(() {
                            _promoType = val ? AppStrings.promo1plus1 : AppStrings.promoNone;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: Colors.indigo,
                      ),
                      if (_promoType != AppStrings.promoNone) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: AppStrings.promotionLabel, border: OutlineInputBorder()),
                          value: _promoType,
                          items: _promoTypes.map((pt) => DropdownMenuItem(value: pt, child: Text(pt))).toList(),
                          onChanged: (val) => setState(() => _promoType = val),
                        ),
                        if (_promoType == AppStrings.promoDiscountPercent) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _discountPercentController,
                            decoration: const InputDecoration(labelText: AppStrings.discountPercentLabel, border: OutlineInputBorder()),
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: 24),
              // SEZIONE 2: RILEVAZIONE PREZZO
              _buildSectionHeader(AppStrings.priceEntrySection, Icons.payments_outlined),
              const SizedBox(height: 12),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  initiallyExpanded: widget.preselectedStoreId != null,
                  title: const Text('Prezzo e Supermercato', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_selectedStoreId != null ? 'Punto vendita selezionato' : 'Tocca per compilare'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _pricePerKgController,
                            decoration: const InputDecoration(labelText: AppStrings.pricePerKgAuto, border: OutlineInputBorder()),
                            readOnly: true,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(labelText: AppStrings.storeSelectionPrompt, border: OutlineInputBorder()),
                                  value: stores.any((s) => s.id == _selectedStoreId) ? _selectedStoreId : null,
                                  items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                                  onChanged: (val) => setState(() => _selectedStoreId = val),
                                  validator: (value) => (_priceController.text.isNotEmpty && value == null) ? AppStrings.validationStoreRequired : null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_business, size: 30, color: Colors.indigo),
                                onPressed: () async {
                                  final id = await Navigator.push<String>(context, MaterialPageRoute(builder: (_) => const AddStoreScreen()));
                                  if (id != null) setState(() => _selectedStoreId = id);
                                },
                              )
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _priceController,
                            focusNode: _priceFocusNode,
                            decoration: const InputDecoration(labelText: AppStrings.recordedPriceRequired, border: OutlineInputBorder()),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(labelText: AppStrings.promotionLabel, border: OutlineInputBorder()),
                            value: _promoType,
                            items: _promoTypes.map((pt) => DropdownMenuItem(value: pt, child: Text(pt))).toList(),
                            onChanged: (val) => setState(() => _promoType = val),
                          ),
                          if (_promoType == AppStrings.promoDiscountPercent) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _discountPercentController,
                              decoration: const InputDecoration(labelText: AppStrings.discountPercentLabel, border: OutlineInputBorder()),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                          if (_promoType != AppStrings.promoNone) _buildExpiryPicker(),
                        ],
                      ),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 24),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
      ],
    );
  }

  Widget _buildImageAction(IconData icon, VoidCallback onPressed) {
    return CircleAvatar(
      backgroundColor: Colors.indigo.shade100,
      radius: 18,
      child: IconButton(icon: Icon(icon, color: Colors.indigo, size: 18), onPressed: onPressed),
    );
  }

  Widget _buildExpiryPicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(_promoValidUntil == null ? AppStrings.noExpirySelected : '${AppStrings.expiryDatePrefix} ${DateFormat('dd/MM/yyyy').format(_promoValidUntil!)}'),
      trailing: IconButton(
        icon: const Icon(Icons.calendar_month),
        onPressed: () async {
          final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
          if (date != null) setState(() => _promoValidUntil = date);
        },
      ),
    );
  }
}
