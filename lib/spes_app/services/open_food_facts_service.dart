import 'package:openfoodfacts/openfoodfacts.dart' as off;
import '../models/product.dart';
import '../models/category.dart';
import '../constants/app_strings.dart';

class OpenFoodFactsService {
  static const String _userAgentName = 'SpesApp-Refactoring';
  
  void init() {
    off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(name: _userAgentName);
    off.OpenFoodAPIConfiguration.globalLanguages = <off.OpenFoodFactsLanguage>[
      off.OpenFoodFactsLanguage.ITALIAN,
      off.OpenFoodFactsLanguage.ENGLISH,
    ];
    off.OpenFoodAPIConfiguration.globalCountry = off.OpenFoodFactsCountry.ITALY;
  }

  Future<Product?> fetchProductByBarcode(String barcode, {bool dataSaver = false}) async {
    try {
      final List<off.ProductField> targetFields = [
        off.ProductField.NAME,
        off.ProductField.BRANDS,
        off.ProductField.QUANTITY,
        off.ProductField.CATEGORIES_TAGS,
        off.ProductField.INGREDIENTS_TEXT,
        off.ProductField.NUTRISCORE,
        off.ProductField.ECOSCORE_DATA,
      ];
      
      if (!dataSaver) {
        targetFields.add(off.ProductField.IMAGE_FRONT_URL);
      }

      final off.ProductQueryConfiguration configuration = off.ProductQueryConfiguration(
        barcode,
        fields: targetFields,
        version: off.ProductQueryVersion.v3,
      );

      final off.ProductResultV3 result = await off.OpenFoodAPIClient.getProductV3(configuration);

      if (result.status == off.ProductResultV3.statusSuccess && result.product != null) {
        final off.Product offProductSource = result.product!;
        
        final normalization = _normalizeQuantity(offProductSource.quantity ?? '');
        final categoryTag = offProductSource.categoriesTags?.firstOrNull;
        
        return Product(
          barcode: barcode,
          name: offProductSource.productName ?? 'Prodotto Sconosciuto',
          brand: offProductSource.brands,
          description: offProductSource.ingredientsText,
          imageUrl: offProductSource.imageFrontUrl,
          weight: normalization.value,
          weightUnit: normalization.unit,
          // We store the ID here. The UI will look up/create the category.
          category: categoryTag,
          // pricePerKg will be calculated when user enters the price
          rawOffData: result.product?.toJson().toString(),
        );
      }
    } catch (e) {
      print('Error fetching from Open Food Facts: $e');
    }
    return null;
  }

  /// Fetches a list of common categories from Open Food Facts.
  /// We focus on a curated list of top-level categories in Italian.
  Future<List<Category>> fetchCommonCategories() async {
    // For the sake of performance and relevance, we use a baseline list of common taxonomy tags
    // that are frequently used in Italy.
    final List<String> commonCategoryTags = [
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
    ];

    return commonCategoryTags.map((tag) {
      return Category(
        id: tag,
        name: cleanCategoryName(tag),
      );
    }).toList();
  }

  /// Utility to clean a category tag (e.g. "it:bevande-analcoliche" -> "Bevande analcoliche")
  String cleanCategoryName(String tag) {
    // Remove language prefixes
    String name = tag.replaceAll(RegExp(r'^[a-z]{2}:'), '');
    // Replace dashes with spaces
    name = name.replaceAll('-', ' ');
    // Capitalize first letter
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  _NormalizedQuantity _normalizeQuantity(String quantity) {
    if (quantity.isEmpty) return _NormalizedQuantity(null, AppStrings.unitKg);

    final clean = quantity.toLowerCase().replaceAll(',', '.');
    final numberMatch = RegExp(r'(\d+(\.\d+)?)').firstMatch(clean);
    
    if (numberMatch == null) return _NormalizedQuantity(null, AppStrings.unitKg);
    
    double value = double.parse(numberMatch.group(1)!);
    String unit = AppStrings.unitKg;

    if (clean.contains(' g') || clean.endsWith('g')) {
      value = value / 1000;
      unit = AppStrings.unitKg;
    } else if (clean.contains('ml')) {
      value = value / 1000;
      unit = AppStrings.unitL;
    } else if (clean.contains('kg')) {
      unit = AppStrings.unitKg;
    } else if (clean.contains(' l') || clean.endsWith('l')) {
      unit = AppStrings.unitL;
    } else if (clean.contains('pz') || clean.contains('unit')) {
      unit = AppStrings.unitPz;
    }

    return _NormalizedQuantity(value, unit);
  }
}

class _NormalizedQuantity {
  final double? value;
  final String unit;

  _NormalizedQuantity(this.value, this.unit);
}
