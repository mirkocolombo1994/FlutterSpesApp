import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/store.dart';
import '../providers/store_provider.dart';
import '../providers/price_history_provider.dart';
import '../providers/product_provider.dart';
import '../services/spes_app_database_helper.dart';
import '../constants/app_strings.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  final Store? storeToEdit;
  const AddStoreScreen({super.key, this.storeToEdit});

  @override
  ConsumerState<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends ConsumerState<AddStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _chainCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  String _name = '';
  String _chain = '';
  String _phone = '';
  double? _latitude;
  double? _longitude;
  bool _isClosed = false;

  @override
  void initState() {
    super.initState();
    if (widget.storeToEdit != null) {
      _name = widget.storeToEdit!.name;
      _nameCtrl.text = _name;
      _chainCtrl.text = widget.storeToEdit!.chain ?? '';
      _phoneCtrl.text = widget.storeToEdit!.phone ?? '';
      _latitude = widget.storeToEdit!.latitude;
      _longitude = widget.storeToEdit!.longitude;
      _isClosed = widget.storeToEdit!.isClosed;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _chainCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _saveStore() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final store = Store(
        id: widget.storeToEdit?.id ?? const Uuid().v4(),
        name: _name,
        chain: _chain,
        phone: _phone,
        latitude: _latitude,
        longitude: _longitude,
        isClosed: _isClosed,
      );
      
      if (widget.storeToEdit == null) {
        ref.read(storeProvider.notifier).addStore(store);
      } else {
        ref.read(storeProvider.notifier).updateStore(store);
      }
      Navigator.pop(context, store.id);
    }
  }

  void _showDeleteOrCloseDialog(bool isDelete) {
    bool deleteExclusive = true; // Consigliato eliminare lo storico orfano

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isDelete ? AppStrings.deleteStoreTitle : (_isClosed ? AppStrings.reopenStoreTitle : AppStrings.closeStoreTitle)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   Text(isDelete 
                     ? AppStrings.deleteStoreConfirm 
                     : (_isClosed ? AppStrings.reopenStoreConfirm : AppStrings.closeStoreConfirm)),
                   if (isDelete || !_isClosed) ...[
                     const SizedBox(height: 16),
                     CheckboxListTile(
                       title: const Text(AppStrings.deleteRelatedData, style: TextStyle(fontSize: 14)),
                       value: deleteExclusive,
                       onChanged: (val) {
                         setDialogState(() {
                           deleteExclusive = val == true;
                         });
                       },
                       contentPadding: EdgeInsets.zero,
                       controlAffinity: ListTileControlAffinity.leading,
                     ),
                   ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text(AppStrings.cancel),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDelete ? Colors.red : Colors.orange,
                  ),
                  onPressed: () => Navigator.pop(ctx, deleteExclusive),
                  child: const Text(AppStrings.confirmAction, style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    ).then((result) async {
      if (result != null && result is bool) {
        final doDeleteExclusive = result;
        final storeId = widget.storeToEdit!.id;
        final dbHelper = SpesAppDatabaseHelper.instance;

        if ((isDelete || (!_isClosed && doDeleteExclusive)) && doDeleteExclusive) {
          await dbHelper.deleteProductsExclusiveToStore(storeId);
          await dbHelper.deletePriceHistoryForStore(storeId);
        }

        if (isDelete) {
          await ref.read(storeProvider.notifier).deleteStore(storeId);
        } else {
          _isClosed = !_isClosed;
          final updatedStore = Store(
            id: storeId,
            name: _name,
            chain: _chain,
            phone: _phone,
            latitude: _latitude,
            longitude: _longitude,
            isClosed: _isClosed,
          );
          await ref.read(storeProvider.notifier).updateStore(updatedStore);
        }

        ref.invalidate(priceHistoryProvider);
        ref.invalidate(productProvider);

        if (mounted) {
          Navigator.pop(context, 'deleted_or_updated');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.storeToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? AppStrings.editStore : AppStrings.newStore),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveStore,
            tooltip: AppStrings.save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_isClosed)
               Container(
                 padding: const EdgeInsets.all(8),
                 color: Colors.red.shade100,
                 child: const Row(
                   children: [
                     Icon(Icons.warning, color: Colors.red),
                     SizedBox(width: 8),
                     Expanded(child: Text(AppStrings.storeClosedWarning, style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                   ],
                 )
               ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: AppStrings.storeNameRequired, border: OutlineInputBorder()),
              validator: (value) => value == null || value.isEmpty ? AppStrings.enterStoreName : null,
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _chainCtrl,
              decoration: const InputDecoration(labelText: AppStrings.storeChainLabel, border: OutlineInputBorder()),
              onSaved: (value) => _chain = value ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: AppStrings.phoneLabel, border: OutlineInputBorder()),
              keyboardType: TextInputType.phone,
              onSaved: (value) => _phone = value ?? '',
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text(AppStrings.selectLocationOnMap),
              onPressed: () async {
                final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => const MapPickerScreen()));
                if (result != null && result is Map<String, dynamic>) {
                  setState(() {
                    _latitude = (result['latLng'] as LatLng).latitude;
                    _longitude = (result['latLng'] as LatLng).longitude;
                    
                    final String? foundName = result['name'];
                    if (foundName != null && foundName.isNotEmpty && !foundName.contains('Coordinate scelte')) {
                       if (_nameCtrl.text.isEmpty) _nameCtrl.text = foundName;
                       if (_chainCtrl.text.isEmpty) _chainCtrl.text = foundName;
                    }
                  });
                }
              },
            ),
            if (_latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 16),
                child: Text('${AppStrings.coordinatesPrefix} ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}', 
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
            
            if (isEditing) ...[
              const Divider(height: 32),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: _isClosed ? Colors.green : Colors.orange),
                icon: Icon(_isClosed ? Icons.lock_open : Icons.lock, color: Colors.white),
                label: Text(_isClosed ? AppStrings.reopenStoreTitle : AppStrings.markAsClosed, style: const TextStyle(color: Colors.white)),
                onPressed: () { _formKey.currentState!.save(); _showDeleteOrCloseDialog(false); },
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                icon: const Icon(Icons.delete),
                label: const Text(AppStrings.deleteDefinitively),
                onPressed: () { _formKey.currentState!.save(); _showDeleteOrCloseDialog(true); },
              )
            ]
          ],
        ),
      ),
    );
  }
}
