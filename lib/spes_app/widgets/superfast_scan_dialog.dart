import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/product.dart';
import '../models/price_history.dart';
import '../services/ai_service.dart';
import '../services/open_food_facts_service.dart';
import '../services/spes_app_database_helper.dart';
import '../constants/app_strings.dart';
import '../providers/settings_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/open_food_facts_provider.dart';

class SuperFastScanDialog extends ConsumerStatefulWidget {
  final String scannedBarcode;
  final String storeId;
  final VoidCallback onCompleted;

  const SuperFastScanDialog({
    super.key,
    required this.scannedBarcode,
    required this.storeId,
    required this.onCompleted,
  });

  @override
  ConsumerState<SuperFastScanDialog> createState() => _SuperFastScanDialogState();
}

enum SuperFastStage { priceEntry, cameraPrompt, aiLoading, aiConfirmation }

class _SuperFastScanDialogState extends ConsumerState<SuperFastScanDialog> {
  // Stage controller
  SuperFastStage _currentStage = SuperFastStage.priceEntry;

  // Controllers e Focus
  final TextEditingController _priceController = TextEditingController();
  final FocusNode _priceFocusNode = FocusNode();

  // Background OFF Search State
  Future<Product?>? _offSearchFuture;
  Product? _offProduct;
  bool _isOffSearching = true;

  // AI & Camera State
  File? _productImageFile;
  AIProductDetails? _aiDetectedDetails;
  String _aiLoadingText = 'Avvio analisi visiva...';
  Timer? _aiLoadingTimer;
  int _loadingStep = 0;

  // Modifica dati estratti dall'IA
  final TextEditingController _aiNameController = TextEditingController();
  final TextEditingController _aiBrandController = TextEditingController();
  final TextEditingController _aiWeightController = TextEditingController();
  String _selectedCategory = 'it:conserve';

  @override
  void initState() {
    super.initState();
    // 1. Lancia la ricerca in background su OFF
    _offSearchFuture = _runBackgroundOffSearch();

    // 2. Richiedi il focus sul prezzo immediatamente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _priceFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    _priceFocusNode.dispose();
    _aiLoadingTimer?.cancel();
    _aiNameController.dispose();
    _aiBrandController.dispose();
    _aiWeightController.dispose();
    super.dispose();
  }

  Future<Product?> _runBackgroundOffSearch() async {
    try {
      final product = await ref.read(openFoodFactsProvider).fetchProductByBarcode(widget.scannedBarcode);
      if (mounted) {
        setState(() {
          _offProduct = product;
          _isOffSearching = false;
        });
      }
      return product;
    } catch (e) {
      if (mounted) {
        setState(() {
          _isOffSearching = false;
        });
      }
      return null;
    }
  }

  void _startAiLoadingTextAnimation() {
    _loadingStep = 0;
    final loadingPhrases = [
      'Estrazione dei colori dominanti...',
      'Identificazione della forma del packaging...',
      'Analisi del logo e della tipografia...',
      'Riconoscimento del marchio...',
      'Classificazione della categoria alimentare...',
      'Rilevamento del formato e peso...',
      'Perfezionamento dei metadati...'
    ];

    _aiLoadingTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (mounted) {
        setState(() {
          _loadingStep = (_loadingStep + 1) % loadingPhrases.length;
          _aiLoadingText = loadingPhrases[_loadingStep];
        });
      }
    });
  }

  Future<void> _submitPrice() async {
    final priceText = _priceController.text.replaceAll(',', '.');
    final double? price = double.tryParse(priceText);

    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.priceInvalidValidator),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Se la ricerca OFF in background è ancora in corso, mostriamo una breve attesa
    if (_isOffSearching) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.indigo),
                  SizedBox(height: 16),
                  Text(AppStrings.offSearching, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      );

      // Aspetta il completamento dell'asincrono con un timeout di 3 secondi
      await Future.any([
        _offSearchFuture!,
        Future.delayed(const Duration(seconds: 3)),
      ]);

      if (mounted) {
        Navigator.pop(context); // Chiude la modale di attesa
      }
    }

    if (_offProduct != null) {
      // PRODOTTO TROVATO IN OFF -> Inseriamo direttamente nel DB e Carrello!
      await _saveProductAndAddToCart(_offProduct!, price);
      _closeDialogWithSuccess(_offProduct!.name);
    } else {
      // PRODOTTO NON TROVATO IN OFF -> Passiamo alla fase della fotocamera!
      setState(() {
        _currentStage = SuperFastStage.cameraPrompt;
      });
    }
  }

  Future<void> _captureProductPhoto() async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70, // Comprime per ottimizzare le performance
        maxWidth: 1024,
      );

      if (image == null) return;

      setState(() {
        _productImageFile = File(image.path);
        _currentStage = SuperFastStage.aiLoading;
      });

      _startAiLoadingTextAnimation();

      // Recuperiamo le impostazioni (chiave API Gemini)
      final settings = ref.read(settingsProvider);

      // Eseguiamo l'analisi visiva con l'IA
      final details = await AIService.instance.analyzeProductImage(
        _productImageFile!,
        apiKey: settings.geminiApiKey,
      );

      _aiLoadingTimer?.cancel();

      if (mounted) {
        setState(() {
          _aiDetectedDetails = details;
          _aiNameController.text = details.name;
          _aiBrandController.text = details.brand;
          _aiWeightController.text = details.weight.toString();
          _selectedCategory = details.categoryId;
          _currentStage = SuperFastStage.aiConfirmation;
        });
      }
    } catch (e) {
      _aiLoadingTimer?.cancel();
      if (mounted) {
        setState(() {
          _currentStage = SuperFastStage.cameraPrompt;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.aiAnalysisFailed),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _confirmAiDetails() async {
    final name = _aiNameController.text.trim();
    final brand = _aiBrandController.text.trim();
    final weightText = _aiWeightController.text.replaceAll(',', '.');
    final double weight = double.tryParse(weightText) ?? 1.0;
    final priceText = _priceController.text.replaceAll(',', '.');
    final double price = double.tryParse(priceText) ?? 0.0;

    if (name.isEmpty) return;

    final newProduct = Product(
      barcode: widget.scannedBarcode,
      name: name,
      brand: brand.isNotEmpty ? brand : null,
      category: _selectedCategory,
      imageUrl: _productImageFile?.path, // Salviamo il path locale dell'immagine catturata!
      weight: weight,
      weightUnit: _aiDetectedDetails?.weightUnit ?? 'g',
      description: _aiDetectedDetails?.tags != null && _aiDetectedDetails!.tags.isNotEmpty
          ? 'Tag IA: ${_aiDetectedDetails!.tags}'
          : null,
    );

    await _saveProductAndAddToCart(newProduct, price);
    _closeDialogWithSuccess(newProduct.name);
  }

  Future<void> _saveProductAndAddToCart(Product product, double price) async {
    // 1. Salva il prodotto
    await ref.read(productProvider.notifier).addProduct(product);

    // 2. Registra lo storico prezzi
    final ph = PriceHistory(
      id: const Uuid().v4(),
      productBarcode: product.barcode,
      storeId: widget.storeId,
      price: price,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
    await SpesAppDatabaseHelper.instance.insertPriceHistory(ph);

    // 3. Aggiunge al carrello (con Riverpod cartProvider)
    final newItem = CartItem(
      id: const Uuid().v4(),
      barcode: product.barcode,
      name: product.name,
      price: price,
      unitPrice: product.pricePerKg,
      imageUrl: product.imageUrl,
      status: CartItemStatus.ok,
      quantity: 1,
    );
    ref.read(cartProvider.notifier).addItem(newItem);
  }

  void _closeDialogWithSuccess(String productName) {
    widget.onCompleted();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text('${AppStrings.addedSuccess} $productName')),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 8,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(24),
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStageContent(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    IconData icon;
    Color color;
    String title;

    switch (_currentStage) {
      case SuperFastStage.priceEntry:
        icon = Icons.bolt;
        color = Colors.amber.shade700;
        title = AppStrings.superfastPricePrompt;
        break;
      case SuperFastStage.cameraPrompt:
        icon = Icons.camera_alt;
        color = Colors.indigo;
        title = 'Foto Richiesta';
        break;
      case SuperFastStage.aiLoading:
        icon = Icons.psychology;
        color = Colors.purple;
        title = 'Analisi IA';
        break;
      case SuperFastStage.aiConfirmation:
        icon = Icons.verified;
        color = Colors.green;
        title = AppStrings.aiConfirmTitle;
        break;
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStageContent() {
    switch (_currentStage) {
      case SuperFastStage.priceEntry:
        return _buildPriceEntryView();
      case SuperFastStage.cameraPrompt:
        return _buildCameraPromptView();
      case SuperFastStage.aiLoading:
        return _buildAiLoadingView();
      case SuperFastStage.aiConfirmation:
        return _buildAiConfirmationView();
    }
  }

  Widget _buildPriceEntryView() {
    return Column(
      children: [
        Text(
          'Codice: ${widget.scannedBarcode}',
          style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _priceController,
          focusNode: _priceFocusNode,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixText: '€ ',
            prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.indigo, width: 2),
            ),
          ),
          onSubmitted: (_) => _submitPrice(),
        ),
        const SizedBox(height: 16),
        // Mini info status background search
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: _isOffSearching
                    ? const CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo)
                    : Icon(
                        _offProduct != null ? Icons.check_circle : Icons.warning_amber,
                        color: _offProduct != null ? Colors.green : Colors.amber.shade700,
                        size: 14,
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                _isOffSearching
                    ? 'Ricerca OFF in background...'
                    : (_offProduct != null ? 'Prodotto riconosciuto!' : 'Prodotto non su OFF'),
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(AppStrings.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _submitPrice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Avanti'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCameraPromptView() {
    return Column(
      children: [
        const Text(
          AppStrings.offNotFound,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _captureProductPhoto,
          icon: const Icon(Icons.photo_camera, size: 24),
          label: const Text(AppStrings.takeProductPhoto),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            elevation: 2,
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(AppStrings.cancel),
        ),
      ],
    );
  }

  Widget _buildAiLoadingView() {
    return Column(
      children: [
        const SizedBox(height: 10),
        const SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            strokeWidth: 4,
            color: Colors.purple,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          _aiLoadingText,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.purple),
        ),
        const SizedBox(height: 8),
        const Text(
          'L\'elaborazione dell\'immagine può richiedere qualche istante',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildAiConfirmationView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          AppStrings.aiConfirmSubtitle,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
        const SizedBox(height: 12),
        // Mini anteprima foto
        if (_productImageFile != null)
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                height: 80,
                width: 120,
                child: Image.file(_productImageFile!, fit: BoxFit.cover),
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Nome Prodotto
        TextField(
          controller: _aiNameController,
          decoration: const InputDecoration(
            labelText: 'Nome Prodotto',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 10),
        // Marca
        TextField(
          controller: _aiBrandController,
          decoration: const InputDecoration(
            labelText: 'Marca',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
        const SizedBox(height: 10),
        // Quantità e Unità
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _aiWeightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Formato',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(_aiDetectedDetails?.weightUnit ?? 'g', style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Categoria Dropdown
        const Text('Categoria Rilevata', style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory,
              isExpanded: true,
              items: [
                'it:bevande', 'it:latticini', 'it:snack', 'it:prodotti-da-forno',
                'it:salumi', 'it:carne', 'it:pesce', 'it:frutta-e-verdura',
                'it:pasta', 'it:riso', 'it:conserve', 'it:olio-e-grassi',
                'it:dolci', 'it:gelati', 'it:surgelati', 'it:uova',
                'it:formaggi', 'it:pizze', 'it:sughi', 'it:spezie-e-erbe',
                'it:cereali-per-la-colazione', 'it:marmellate-e-confetture',
                'it:pane', 'it:biscotti', 'it:merendine', 'it:cioccolato',
                'it:vino', 'it:birra', 'it:succhi-di-frutta', 'it:acqua-minerale',
                'it:detersivi', 'it:igiene-personale', 'it:carta-e-plastica',
                'it:caffe-e-te', 'it:legumi'
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.replaceFirst('it:', '').toUpperCase(), style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedCategory = val;
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Pulsanti
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Annulla'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _confirmAiDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Conferma'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
