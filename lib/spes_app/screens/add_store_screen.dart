import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'map_picker_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/store.dart';
import '../providers/store_provider.dart';

class AddStoreScreen extends ConsumerStatefulWidget {
  const AddStoreScreen({super.key});

  @override
  ConsumerState<AddStoreScreen> createState() => _AddStoreScreenState();
}

class _AddStoreScreenState extends ConsumerState<AddStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _chain = '';
  String _phone = '';
  // Mappa/Coordinate placeholder per ora
  double? _latitude;
  double? _longitude;

  void _saveStore() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final newStore = Store(
        id: const Uuid().v4(),
        name: _name,
        chain: _chain,
        phone: _phone,
        latitude: _latitude,
        longitude: _longitude,
      );
      
      ref.read(storeProvider.notifier).addStore(newStore);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Supermercato'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveStore,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Nome Supermercato *',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? 'Inserisci un nome' : null,
              onSaved: (value) => _name = value!,
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Catena (es. Esselunga, Conad)',
                border: OutlineInputBorder(),
              ),
              onSaved: (value) => _chain = value ?? '',
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Telefono',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              onSaved: (value) => _phone = value ?? '',
            ),
            const SizedBox(height: 16),
            // TODO: Aggiungere mappa con flutter_map per la selezione coordinate
            ElevatedButton.icon(
              icon: const Icon(Icons.map),
              label: const Text('Seleziona Posizione sulla Mappa'),
              onPressed: () async {
                final LatLng? result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapPickerScreen()),
                );

                if (result != null) {
                  setState(() {
                    _latitude = result.latitude;
                    _longitude = result.longitude;
                  });
                }
              },
            ),
            if (_latitude != null && _longitude != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text('Coordinate: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}', 
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
