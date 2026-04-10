import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'barcode_scanner_screen.dart';
import 'add_product_screen.dart';
import '../models/price_history.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/price_history_provider.dart';
import '../providers/store_provider.dart';
import '../models/store.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'dart:io';
import 'dart:async';
import '../constants/app_strings.dart';
import '../providers/settings_provider.dart';
import '../services/promotion_engine.dart';

class CurrentShoppingScreen extends ConsumerStatefulWidget {
  const CurrentShoppingScreen({super.key});
  @override
  ConsumerState<CurrentShoppingScreen> createState() => _CurrentShoppingScreenState();
}

class _CurrentShoppingScreenState extends ConsumerState<CurrentShoppingScreen> {

  bool _gpsFetched = false;
  Timer? _locationTimer;
  bool _isCheckingLocation = false;
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(activeStoreIdProvider) == null && !_gpsFetched) {
        _gpsFetched = true;
        _fetchGpsAndStore(ref).then((storeId) {
          if (storeId != null && mounted) {
            ref.read(activeStoreIdProvider.notifier).setId(storeId);
          }
        });
      }
      _startLocationTimer();
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startLocationTimer() {
    _locationTimer?.cancel();
    final interval = ref.read(settingsProvider).locationCheckInterval;
    _locationTimer = Timer.periodic(Duration(minutes: interval), (timer) {
      _checkLocationChange();
    });
  }

  Future<void> _checkLocationChange() async {
    if (_isCheckingLocation || _isShowingDialog) return;
    final activeStoreId = ref.read(activeStoreIdProvider);
    if (activeStoreId == null) return;

    _isCheckingLocation = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      final stores = ref.read(storeProvider);
      final activeStore = stores.where((s) => s.id == activeStoreId).firstOrNull;

      if (activeStore != null && activeStore.latitude != null && activeStore.longitude != null) {
        final distance = const Distance();
        final dToActive = distance.as(LengthUnit.Meter, LatLng(pos.latitude, pos.longitude), LatLng(activeStore.latitude!, activeStore.longitude!));

        // Se siamo ancora "dentro" (250m), non facciamo nulla
        if (dToActive < 250) return;

        // Cerchiamo se siamo vicini a un ALTRO store (radius 100m)
        Store? foundStore;
        for (var s in stores) {
          if (s.id == activeStoreId) continue;
          if (s.latitude != null && s.longitude != null) {
            final d = distance.as(LengthUnit.Meter, LatLng(pos.latitude, pos.longitude), LatLng(s.latitude!, s.longitude!));
            if (d < 100) {
              foundStore = s;
              break;
            }
          }
        }

        // Se non trovato in DB, cerchiamo online (Overpass/Nominatim)
        if (foundStore == null) {
          final placeName = await LocationService.lookupSupermarketName(pos.latitude, pos.longitude);
          if (placeName != null) {
             // Verifichiamo che non sia lo stesso nome dello store attivo (magari stessa catena)
             if (placeName.toLowerCase() != activeStore.name.toLowerCase()) {
               _showLocationChangeDialog(placeName, pos.latitude, pos.longitude);
             }
          }
        } else {
          _showLocationChangeDialog(foundStore.name, foundStore.latitude!, foundStore.longitude!, existingStore: foundStore);
        }
      }
    } catch (_) {
    } finally {
      _isCheckingLocation = false;
    }
  }

  void _showLocationChangeDialog(String storeName, double lat, double lon, {Store? existingStore}) {
    if (!mounted || _isShowingDialog) return;
    
    setState(() => _isShowingDialog = true);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.locationChangedTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppStrings.locationChangedMessage}$storeName.'),
            const SizedBox(height: 12),
            const Text(AppStrings.locationChangedQuestion),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isShowingDialog = false);
            },
            child: const Text(AppStrings.stayAtCurrentStore),
          ),
          ElevatedButton(
            onPressed: () async {
              String targetStoreId;
              if (existingStore != null) {
                targetStoreId = existingStore.id;
              } else {
                final newStore = Store(
                  id: const Uuid().v4(),
                  name: storeName,
                  chain: storeName,
                  latitude: lat,
                  longitude: lon,
                );
                await ref.read(storeProvider.notifier).addStore(newStore);
                targetStoreId = newStore.id;
              }

              ref.read(activeStoreIdProvider.notifier).setId(targetStoreId);
              ref.read(cartProvider.notifier).clear();
              
              if (mounted) {
                Navigator.pop(ctx);
                setState(() => _isShowingDialog = false);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${AppStrings.navPuntiVendita}: $storeName'),
                  backgroundColor: Colors.indigo,
                ));
              }
            },
            child: const Text(AppStrings.switchToNewStore),
          ),
        ],
      ),
    );
  }

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
             content: Text('${AppStrings.newStoreAutoSaved} $placeName'),
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

    return Column(
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
                    const Text(AppStrings.storeSelectorLabel, style: TextStyle(fontSize: 12, color: Colors.indigo)),
                    Text(
                      currentStore?.name ?? AppStrings.storeNotDetected,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _showStoreSelector(context, ref, stores),
                icon: const Icon(Icons.edit_location_alt, size: 18),
                label: const Text(AppStrings.changeStore),
              ),
            ],
          ),
        ),
        Expanded(
          child: cartItems.isEmpty
              ? const Center(child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    AppStrings.emptyCart,
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
                      leading: _buildItemLeading(item),
                      title: Row(
                        children: [
                          Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (item.status == CartItemStatus.warning)
                             Tooltip(
                               message: AppStrings.priceMissingInStore,
                               triggerMode: TooltipTriggerMode.tap,
                               child: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                             ),
                          if (item.status == CartItemStatus.error)
                             Tooltip(
                               message: AppStrings.productNotIndexedInStore,
                               triggerMode: TooltipTriggerMode.tap,
                               child: const Icon(Icons.error_outline, color: Colors.red, size: 20),
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
                          if (item.isPromoFree && item.originalPrice != null)
                             Text(
                               '€${item.originalPrice!.toStringAsFixed(2)}', 
                               style: const TextStyle(
                                 decoration: TextDecoration.lineThrough,
                                 color: Colors.grey,
                                 fontSize: 12
                               )
                             ),
                          Text(
                            item.isPromoFree 
                              ? 'OMAGGIO (€0.00)' 
                              : isFresh 
                                ? '${AppStrings.freshIndicatorLabel} - €${item.price.toStringAsFixed(2)}' 
                                : '${item.price.toStringAsFixed(2)} ${AppStrings.pricePerUnit}',
                            style: TextStyle(
                              color: item.isPromoFree ? Colors.green : null,
                              fontWeight: item.isPromoFree ? FontWeight.bold : null,
                            ),
                          ),
                          if (item.unitPrice != null && item.unitPrice! > 0 && !item.isPromoFree)
                            Text(
                              '(${item.unitPrice!.toStringAsFixed(2)} €/unità)',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                            ),
                        ],
                      ),
                      trailing: (() {
                        final isChild = item.isPromoFree || item.parentId != null;
                        final canModify = !isChild; // I genitori sono sempre modificabili per gestire i multiset
                        
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_circle_outline, color: (item.quantity > 1 && canModify) ? Colors.indigo : Colors.grey),
                              onPressed: (item.quantity > 1 && canModify)
                                  ? () => ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1)
                                  : null,
                            ),
                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            IconButton(
                              icon: Icon(Icons.add_circle_outline, color: canModify ? Colors.indigo : Colors.grey),
                              onPressed: canModify
                                  ? () async {
                                      final rule = PromotionEngine.getRule(item.promoType);
                                      if (rule != null && rule.shouldTriggerScan(item.quantity) && mounted) {
                                        // [FIX] Verifichiamo quanti omaggi abbiamo già riscattato per questo genitore
                                        final cart = ref.read(cartProvider);
                                        // Sommiamo correttamente le quantità fisiche degli omaggi
                                        final currentFreeCount = cart
                                            .where((i) => i.parentId == item.id)
                                            .fold<int>(0, (sum, i) => sum + i.quantity);
                                        // Calcoliamo quanti omaggi dovremmo avere in base ai pezzi paganti attuali
                                        final expectedFreeCount = (item.quantity ~/ rule.paidPiecesPerSet) * rule.freeItemsCount;

                                        if (currentFreeCount < expectedFreeCount) {
                                          // Siamo sotto la soglia degli omaggi previsti -> Triggeriamo il dialogo
                                          await _handlePromoScanning(context, ref, item, rule);
                                        } else {
                                          // Abbiamo già tutti gli omaggi per i prodotti attuali -> Aumentiamo i paganti
                                          ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
                                        }
                                      } else {
                                        // Nessun trigger promozionale (es. 2.5/2 non è intero o promo nulla) -> Aumentiamo i paganti
                                        ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
                                      }
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => ref.read(cartProvider.notifier).removeItem(item.id),
                            ),
                          ],
                        );
                      })(),
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
              const Text(AppStrings.totalLabel, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text('€${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: FloatingActionButton.extended(
            icon: const Icon(Icons.qr_code_scanner, size: 30),
            label: const Text(AppStrings.addProductLabel, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            elevation: 6,
            onPressed: () async {
              final gpsFuture = _fetchGpsAndStore(ref);
              final String? scannedCode = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
              );
              if (scannedCode != null) {
                showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
                final storeId = await gpsFuture;
                if (mounted) Navigator.pop(context);
                if (storeId != null && ref.read(activeStoreIdProvider) == null) {
                   ref.read(activeStoreIdProvider.notifier).setId(storeId);
                }
                final products = ref.read(productProvider);
                final existingProduct = products.where((p) => p.barcode == scannedCode).firstOrNull;
                String? finalBarcodeToAdd;
                
                if (existingProduct != null) {
                  final currentStoreId = ref.read(activeStoreIdProvider);
                  bool handled = false;
                  
                  if (currentStoreId != null) {
                    final history = await ref.read(priceHistoryProvider).getHistoryForProduct(scannedCode);
                    final storeHistory = history.where((h) => h.storeId == currentStoreId).firstOrNull;
                    
                    if (storeHistory != null) {
                      final historyDate = DateTime.fromMillisecondsSinceEpoch(storeHistory.timestamp);
                      final now = DateTime.now();
                      bool isSameDay = historyDate.year == now.year && historyDate.month == now.month && historyDate.day == now.day;
                      
                      if (!isSameDay) {
                        if (mounted) {
                          final bool? confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text(AppStrings.priceValidationTitle),
                              content: Text('${AppStrings.priceValidationMessage}${storeHistory.price.toStringAsFixed(2)}${AppStrings.priceValidationQuestion}'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text(AppStrings.priceChanged),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(AppStrings.priceConfirmed),
                                ),
                              ],
                            ),
                          );
                          
                          if (confirmed == true) {
                            await ref.read(priceHistoryProvider).addPriceHistory(PriceHistory(
                              id: const Uuid().v4(),
                              productBarcode: scannedCode,
                              storeId: currentStoreId,
                              price: storeHistory.price,
                              timestamp: now.millisecondsSinceEpoch,
                              promoType: storeHistory.promoType,
                              promoValidUntil: storeHistory.promoValidUntil,
                            ));
                            finalBarcodeToAdd = scannedCode;
                            handled = true;
                          } else if (confirmed == false) {
                            // Leave handled = false to trigger AddProductScreen below
                          } else {
                            handled = true; // Dismissed
                          }
                        } else {
                           handled = true;
                        }
                      } else {
                        // Already checked today
                        finalBarcodeToAdd = scannedCode;
                        handled = true;
                      }
                    }
                  }
                  
                  if (!handled) {
                    if (mounted) {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddProductScreen(initialBarcode: scannedCode, preselectedStoreId: currentStoreId, isFastMode: true)),
                      );
                      if (result != null && result is String) {
                        finalBarcodeToAdd = result;
                      }
                    }
                  }
                  
                  if (finalBarcodeToAdd != null && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('${AppStrings.addedSuccess} ${existingProduct.name}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ));
                  }
                } else {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AddProductScreen(initialBarcode: scannedCode, preselectedStoreId: ref.read(activeStoreIdProvider), isFastMode: true)),
                  );
                  if (result != null && result is String) {
                    finalBarcodeToAdd = result;
                  }
                }
                if (finalBarcodeToAdd != null) {
                  final productList = ref.read(productProvider);
                  final product = productList.where((p) => p.barcode == finalBarcodeToAdd).firstOrNull;
                  final currentStoreId = ref.read(activeStoreIdProvider);
                  final history = await ref.read(priceHistoryProvider).getHistoryForProduct(finalBarcodeToAdd);
                  final storeHistory = currentStoreId != null ? history.where((h) => h.storeId == currentStoreId).firstOrNull : null;
                  final latestHistory = storeHistory ?? (history.isNotEmpty ? history.first : null);
                  double price = latestHistory?.price ?? 0.0;
                  CartItemStatus status = CartItemStatus.ok;
                  if (currentStoreId != null) {
                    if (storeHistory == null) status = CartItemStatus.error;
                    else if (price <= 0) status = CartItemStatus.warning;
                  }
                  final newItem = CartItem(
                    id: const Uuid().v4(),
                    barcode: finalBarcodeToAdd,
                    name: product?.name ?? AppStrings.unknownProduct,
                    price: price,
                    unitPrice: product?.pricePerKg,
                    promoType: latestHistory?.promoType,
                    imageUrl: product?.imageUrl,
                    status: status,
                  );
                  
                  ref.read(cartProvider.notifier).addItem(newItem);

                  // [MODIFICA] Rimosso l'attivazione automatica al primo scan per evitare di interrompere l'utente.
                  // Il dialogo apparirà ora solo premendo il tasto '+' nel carrello.
                }
              }
            },
          ),
        ),
      ],
    );
  }

  /// Gestisce la scansione dei prodotti in omaggio quando scatta la soglia di una promozione.
  Future<void> _handlePromoScanning(BuildContext context, WidgetRef ref, CartItem parent, PromotionRule rule) async {
    // Quando scatta la soglia, dobbiamo scansionare solo il numero di pezzi omaggio previsti
    final itemsToScan = rule.freeItemsCount;

    for (int i = 1; i <= itemsToScan; i++) {
      if (!mounted) return;

      final bool proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(rule.type),
          content: Text("Ottimo! Hai raggiunto la soglia per l'offerta. Vuoi aggiungere lo stesso prodotto come omaggio o scansionarne uno diverso?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false), 
              child: const Text('Stesso Prodotto'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), 
              child: const Text('Scansiona Altro'),
            ),
          ],
        ),
      ) ?? false;

      if (!proceed) {
        // [LOGICA AGGIORNATA] Se l'utente salta il dialogo, aggiungiamo l'omaggio automaticamente con i dati del genitore
        _addFreeItemFromParent(ref, parent);
        continue;
      }

      final String? scannedCode = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
      );

      if (scannedCode != null && mounted) {
        final products = ref.read(productProvider);
        final product = products.where((p) => p.barcode == scannedCode).firstOrNull;
        
        final history = await ref.read(priceHistoryProvider).getHistoryForProduct(scannedCode);
        final currentStoreId = ref.read(activeStoreIdProvider);
        final storeHistory = currentStoreId != null ? history.where((h) => h.storeId == currentStoreId).firstOrNull : null;
        final originalPrice = storeHistory?.price ?? (history.isNotEmpty ? history.first.price : 0.0);

        ref.read(cartProvider.notifier).addItem(
          CartItem(
            id: const Uuid().v4(),
            barcode: scannedCode,
            name: product?.name ?? AppStrings.unknownProduct,
            price: 0.0,
            originalPrice: originalPrice,
            isPromoFree: true,
            parentId: parent.id,
            imageUrl: product?.imageUrl,
            status: CartItemStatus.ok,
          )
        );
      } else {
        // [LOGICA AGGIORNATA] Se annulla lo scanner, aggiungiamo comunque l'omaggio automatico
        _addFreeItemFromParent(ref, parent);
      }
    }
  }

  /// Helper per aggiungere un prodotto in omaggio usando i dati del prodotto genitore (fallback)
  void _addFreeItemFromParent(WidgetRef ref, CartItem parent) {
    ref.read(cartProvider.notifier).addItem(
      CartItem(
        id: const Uuid().v4(),
        barcode: parent.barcode,
        name: parent.name,
        price: 0.0,
        originalPrice: parent.price,
        isPromoFree: true,
        parentId: parent.id,
        imageUrl: parent.imageUrl,
        status: CartItemStatus.ok,
      )
    );
  }

  Widget _buildItemLeading(dynamic item) {
    ImageProvider? image;
    if (item.imageUrl != null) {
      if (item.imageUrl!.startsWith('http')) {
        image = NetworkImage(item.imageUrl!);
      } else if (File(item.imageUrl!).existsSync()) {
        image = FileImage(File(item.imageUrl!));
      }
    }

    if (image != null) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          image: DecorationImage(
            image: image,
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
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.indigo.shade100,
        child: Text('${item.quantity}x', style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold, fontSize: 13)),
      );
    }
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
