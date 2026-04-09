import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/promotion.dart';
import '../models/product.dart';
import '../services/spes_app_database_helper.dart';

final promotionProvider = NotifierProvider<PromotionNotifier, List<Promotion>>(() {
  return PromotionNotifier();
});

class PromotionNotifier extends Notifier<List<Promotion>> {
  @override
  List<Promotion> build() {
    _loadPromotions();
    return [];
  }

  Future<void> _loadPromotions() async {
    final promos = await SpesAppDatabaseHelper.instance.getPromotions();
    state = promos;
  }

  Future<void> addPromotion(Promotion promo) async {
    await SpesAppDatabaseHelper.instance.insertPromotion(promo);
    await _loadPromotions();
  }

  Future<void> removePromotion(String id) async {
    await SpesAppDatabaseHelper.instance.deletePromotion(id);
    await _loadPromotions();
  }

  Future<List<Product>> getProductsForPromotion(String promoId) async {
    return await SpesAppDatabaseHelper.instance.getProductsForPromotion(promoId);
  }

  Future<void> linkProduct(String promoId, String barcode) async {
    await SpesAppDatabaseHelper.instance.linkProductToPromotion(promoId, barcode);
  }

  Future<void> unlinkProduct(String promoId, String barcode) async {
    await SpesAppDatabaseHelper.instance.unlinkProductFromPromotion(promoId, barcode);
  }
}
