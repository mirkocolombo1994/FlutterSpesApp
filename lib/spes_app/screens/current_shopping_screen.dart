import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'barcode_scanner_screen.dart';
import 'add_product_screen.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/price_history_provider.dart';
import '../providers/store_provider.dart';
import '../models/store.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';

class CurrentShoppingScreen extends ConsumerStatefulWidget {
  const CurrentShoppingScreen({super.key});
  @override
  ConsumerState<CurrentShoppingScreen> createState() => _CurrentShoppingScreenState();
}

class _CurrentShoppingScreenState extends ConsumerState<CurrentShoppingScreen> {

  Future<String?> _fetchGpsAndStore(WidgetRef ref) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
         permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) return null;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high).timeout(const Duration(seconds: 8));

      final stores = ref.read(storeProvider);
      final distance = const Distance();
      Store? closestStore;
      double minDistance = double.infinity;

      for (var s in stores) {
        if (s.latitude != null && s.longitude != null) {
          final d = distance.as(LengthUnit.Meter, LatLng(pos.latitude, pos.longitude), LatLng(s.latitude!, s.longitude!));
          // Raggio di 100 metri
          if (d < 100 && d < minDistance) {
            minDistance = d;
            closestStore = s;
          }
        }
      }

      if (closestStore != null) return closestStore.id;

      // Cerca il nome dalle coordinate se non hai supermercati salvati
      final placeName = await LocationService.lookupSupermarketName(pos.latitude, pos.longitude);
      if (placeName != null) {
        final newStore = Store(
          id: const Uuid().v4(),
          name: placeName,
          chain: placeName,
          latitude: pos.latitude,
          longitude: pos.longitude,
        );
        await ref.read(storeProvider.notifier).addStore(newStore);
        ref.read(newlyAddedStoreIdProvider.notifier).setId(newStore.id);
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text('📍 Nuovo supermercato salvato in automatico: $placeName'),
             backgroundColor: Colors.green,
           ));
        }
        return newStore.id;
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final total = cartItems.fold<double>(0, (sum, item) => sum + (item.price * item.quantity));
    final activeStoreId = ref.watch(activeStoreIdProvider);
    final stores = ref.watch(storeProvider);
    final currentStore = stores.where((s) => s.id == activeStoreId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spesa in Corso'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                ref.read(cartProvider.notifier).clear();
              },
              tooltip: 'Svuota Carrello',
            )
        ],
      ),
      body: Column(
        children: [
          // Selettore Punto Vendita
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.indigo.shade100.withOpacity(0.3),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: Colors.indigo),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Punto Vendita:', style: TextStyle(fontSize: 12, color: Colors.indigo)),
                      Text(
                        currentStore?.name ?? 'Supermercato non rilevato',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showStoreSelector(context, ref, stores),
                  icon: const Icon(Icons.edit_location_alt, size: 18),
                  label: const Text('Cambia'),
                ),
              ],
            ),
          ),
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text(
                      'Il tuo carrello è vuoto.\nScannerizza i prodotti mentre li metti nel carrello fisico per calcolare il totale in tempo reale!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      final isFresh = item.barcode.length == 7 && item.barcode.startsWith('2');
                      
                      return ListTile(
                        leading: item.imageUrl != null && File(item.imageUrl!).existsSync()
                          ? Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: FileImage(File(item.imageUrl!)),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
                                  child: Text('${item.quantity}x', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 10)),
                                ),
                              ),
                            )
                          : CircleAvatar(
                              backgroundColor: Colors.indigo.shade100,
                              child: Text('${item.quantity}x', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                        title: Row(
                          children: [
                            Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                            if (item.status == CartItemStatus.warning)
                               const Tooltip(
                                 message: 'Prezzo mancante in questo negozio',
                                 child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                               ),
                            if (item.status == CartItemStatus.error)
                               const Tooltip(
                                 message: 'Prodotto non censito in questo negozio',
                                 child: Icon(Icons.error_outline, color: Colors.red, size: 20),
                               ),
                            if (item.promoType != null)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.orange),
                                ),
                                child: Text(
                                  item.promoType!,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(isFresh ? 'Fresco - €${item.price.toStringAsFixed(2)}' : '€${item.price.toStringAsFixed(2)} cad.'),
                            if (item.unitPrice != null && item.unitPrice! > 0)
                              Text(
                                '(${item.unitPrice!.toStringAsFixed(2)} €/unità)',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                              ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              border: Border(top: BorderSide(color: Colors.indigo.shade100, width: 2))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Totale Cassa:', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                Text('€${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ),
          const SizedBox(height: 90), // Spazio per non coprire il riepilogo con il FAB
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.qr_code_scanner, size: 30),
        label: const Text('Aggiungi Prodotto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 6,
        onPressed: () async {
          // 1. Avvia la ricerca GPS in sottofondo senza rallentare o bloccare la videocamera!
          final gpsFuture = _fetchGpsAndStore(ref);

          // 2. Apri la fotocamera per scansionare il codice
          final String? scannedCode = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
          );
          
          if (scannedCode != null) {
            // Se la fotocamera si è chiusa velocemente, aspetta che il GPS finisca di cercare in background
            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
            final storeId = await gpsFuture;
            if (mounted) Navigator.pop(context);

            // Se viene rilevato uno store ed è diverso da quello attuale, impostalo o chiedi conferma
            if (storeId != null && ref.read(activeStoreIdProvider) == null) {
               ref.read(activeStoreIdProvider.notifier).setId(storeId);
            }

            // 3. Controlla se il prodotto esiste già in anagrafica
            final products = ref.read(productProvider);
            final existingProduct = products.where((p) => p.barcode == scannedCode).firstOrNull;

            String? finalBarcodeToAdd;

            if (existingProduct != null) {
              // Il prodotto è già conosciuto: "passaggio in cassa" automatico
              finalBarcodeToAdd = scannedCode;
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Aggiunto: ${existingProduct.name}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ));
              }
            } else {
              // Prodotto nuovo, apri la schermata di inserimento
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddProductScreen(initialBarcode: scannedCode, preselectedStoreId: ref.read(activeStoreIdProvider))),
              );
              if (result != null && result is String) {
                finalBarcodeToAdd = result;
              }
            }
            
            // 4. Aggiungi il prodotto al carrello se è stato salvato o confermato
            if (finalBarcodeToAdd != null) {
              final productList = ref.read(productProvider);
              final product = productList.where((p) => p.barcode == finalBarcodeToAdd).firstOrNull;
              
              final currentStoreId = ref.read(activeStoreIdProvider);
              final history = await ref.read(priceHistoryProvider).getHistoryForProduct(finalBarcodeToAdd);
              
              // Se abbiamo uno store attivo, cerchiamo il prezzo specifico per quello store
              final storeHistory = currentStoreId != null ? history.where((h) => h.storeId == currentStoreId).firstOrNull : null;
              final latestHistory = storeHistory ?? (history.isNotEmpty ? history.first : null);
              
              double price = latestHistory?.price ?? 0.0;
              CartItemStatus status = CartItemStatus.ok;
              if (currentStoreId != null) {
                if (storeHistory == null) status = CartItemStatus.error;
                else if (price <= 0) status = CartItemStatus.warning;
              }

              ref.read(cartProvider.notifier).addItem(
                CartItem(
                  id: const Uuid().v4(),
                  barcode: finalBarcodeToAdd,
                  name: product?.name ?? 'Prodotto sconosciuto',
                  price: price,
                  unitPrice: product?.pricePerKg,
                  promoType: latestHistory?.promoType,
                  imageUrl: product?.imageUrl,
                  status: status,
                )
              );
            }
          }
        },
      ),
    );
  }

  void _showStoreSelector(BuildContext context, WidgetRef ref, List<Store> stores) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return ListView.builder(
          itemCount: stores.length,
          itemBuilder: (context, index) {
            final s = stores[index];
            return ListTile(
              leading: const Icon(Icons.store),
              title: Text(s.name),
              trailing: ref.watch(activeStoreIdProvider) == s.id ? const Icon(Icons.check, color: Colors.green) : null,
              onTap: () async {
                ref.read(activeStoreIdProvider.notifier).setId(s.id);
                // Aggiorna tutti i prezzi nel carrello
                await ref.read(cartProvider.notifier).refreshPrices(s.id, ref);
                if (context.mounted) Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }
}
