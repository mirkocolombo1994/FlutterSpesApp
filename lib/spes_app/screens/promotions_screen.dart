import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_strings.dart';
import '../models/promotion.dart';
import '../providers/promotion_provider.dart';
import '../providers/store_provider.dart';
import '../models/product.dart';
import 'barcode_scanner_screen.dart';

class PromotionsScreen extends ConsumerStatefulWidget {
  const PromotionsScreen({super.key});

  @override
  ConsumerState<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends ConsumerState<PromotionsScreen> {
  void _openPromotionDialog({Promotion? existing}) {
    showDialog(
      context: context,
      builder: (context) => _PromotionDialog(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final promos = ref.watch(promotionProvider);
    final stores = ref.watch(storeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.titlePromotions),
      ),
      body: promos.isEmpty
          ? const Center(child: Text(AppStrings.noPromotionsText))
          : ListView.builder(
              itemCount: promos.length,
              itemBuilder: (context, index) {
                final promo = promos[index];
                final store = stores.where((s) => s.id == promo.storeId).firstOrNull;
                final dateFmt = DateFormat('dd/MM/yy');

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text('${promo.name} (${promo.discountPercentage.toStringAsFixed(0)}%)', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(store?.name ?? AppStrings.unknown),
                        Text('${AppStrings.validFromLabel} ${dateFmt.format(promo.validFrom)} - ${AppStrings.validUntilLabel} ${dateFmt.format(promo.validUntil)}'),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PromotionDetailScreen(promotion: promo),
                        ),
                      );
                    },
                    onLongPress: () {
                      // Optionally, dialog for deletion
                      ref.read(promotionProvider.notifier).removePromotion(promo.id);
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openPromotionDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _PromotionDialog extends ConsumerStatefulWidget {
  final Promotion? existing;
  const _PromotionDialog({this.existing});

  @override
  ConsumerState<_PromotionDialog> createState() => _PromotionDialogState();
}

class _PromotionDialogState extends ConsumerState<_PromotionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _discountCtrl;
  String? _storeId;
  DateTime? _validFrom;
  DateTime? _validUntil;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _descCtrl = TextEditingController(text: widget.existing?.description ?? '');
    _discountCtrl = TextEditingController(text: widget.existing?.discountPercentage.toString() ?? '');
    _storeId = widget.existing?.storeId;
    _validFrom = widget.existing?.validFrom;
    _validUntil = widget.existing?.validUntil;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _validFrom != null && _validUntil != null
          ? DateTimeRange(start: _validFrom!, end: _validUntil!)
          : null,
    );
    if (range != null) {
      setState(() {
        _validFrom = range.start;
        _validUntil = range.end;
      });
    }
  }

  void _save() {
    if (_formKey.currentState!.validate() && _validFrom != null && _validUntil != null && _storeId != null) {
      final name = _nameCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final discount = double.tryParse(_discountCtrl.text) ?? 0.0;
      
      final promo = Promotion(
        id: widget.existing?.id ?? const Uuid().v4(),
        name: name,
        description: desc,
        discountPercentage: discount,
        storeId: _storeId!,
        validFrom: _validFrom!,
        validUntil: _validUntil!,
      );

      ref.read(promotionProvider.notifier).addPromotion(promo);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = ref.watch(storeProvider);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return AlertDialog(
      title: Text(widget.existing == null ? AppStrings.addPromotionTitle : AppStrings.editPromotionTitle),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: AppStrings.nameLabel),
                validator: (val) => val!.isEmpty ? AppStrings.validationNameRequired : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: InputDecoration(labelText: AppStrings.descriptionLabel),
              ),
              TextFormField(
                controller: _discountCtrl,
                decoration: InputDecoration(labelText: AppStrings.discountLabel),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _storeId,
                items: stores.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                onChanged: (val) => setState(() => _storeId = val),
                decoration: InputDecoration(labelText: AppStrings.supermarket),
                validator: (val) => val == null ? AppStrings.validationStoreRequired : null,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(_validFrom == null 
                  ? AppStrings.noExpirySelected 
                  : '${dateFmt.format(_validFrom!)} - ${dateFmt.format(_validUntil!)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDateRange,
              ),
              if (_validFrom == null)
                 Text(AppStrings.validationDateRequired, style: TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text(AppStrings.cancel)),
        ElevatedButton(onPressed: _save, child: const Text(AppStrings.add)),
      ],
    );
  }
}

class PromotionDetailScreen extends ConsumerStatefulWidget {
  final Promotion promotion;
  const PromotionDetailScreen({super.key, required this.promotion});

  @override
  ConsumerState<PromotionDetailScreen> createState() => _PromotionDetailScreenState();
}

class _PromotionDetailScreenState extends ConsumerState<PromotionDetailScreen> {
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    final products = await ref.read(promotionProvider.notifier).getProductsForPromotion(widget.promotion.id);
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }

  Future<void> _addProduct() async {
    final String? scannedCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (scannedCode != null) {
      await ref.read(promotionProvider.notifier).linkProduct(widget.promotion.id, scannedCode);
      await _loadProducts();
    }
  }

  Future<void> _removeProduct(String barcode) async {
    await ref.read(promotionProvider.notifier).unlinkProduct(widget.promotion.id, barcode);
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.promotion.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
               showDialog(
                context: context,
                builder: (context) => _PromotionDialog(existing: widget.promotion),
              ).then((_) {
                 // Potrebbe essere cambiato il nome
                 setState(() {});
              });
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _products.isEmpty
              ? const Center(child: Text("Nessun prodotto associato a questa promozione."))
              : ListView.builder(
                  itemCount: _products.length,
                  itemBuilder: (context, index) {
                    final product = _products[index];
                    return ListTile(
                      title: Text(product.name),
                      subtitle: Text(product.barcode),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeProduct(product.barcode),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProduct,
        icon: const Icon(Icons.add_a_photo),
        label: const Text("Associa Prodotto"),
      ),
    );
  }
}
