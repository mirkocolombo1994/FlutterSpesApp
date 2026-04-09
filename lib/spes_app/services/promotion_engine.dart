import '../constants/app_strings.dart';

/// [DESIGN PATTERN: Strategy]
/// L'interfaccia PromotionRule definisce una strategia per gestire diversi tipi di promozioni.
/// Questo permette di aggiungere nuove regole (es. 3x2, 2+1) senza modificare il codice esistente.
abstract class PromotionRule {
  String get type;
  
  /// Numero totale di articoli necessari per completare l'offerta (es. 2 per 1+1, 3 per 3x2).
  int get requiredTotalItems;
  
  /// Numero di articoli che sono considerati "omaggio" nell'offerta.
  int get freeItemsCount;

  /// Indica se l'utente può modificare manualmente la quantità nel carrello.
  /// Per promozioni fisse come 1+1 o 3x2, questo dovrebbe essere false.
  bool get canModifyQuantity;

  /// Restituisce il messaggio da mostrare all'utente durante la scansione.
  String getScanPrompt(int currentScanned);
}

/// [DESIGN PATTERN: Concrete Strategy]
/// Implementazione specifica per la promozione "1+1".
class OnePlusOneRule implements PromotionRule {
  @override
  String get type => AppStrings.promo1plus1;

  @override
  int get requiredTotalItems => 2;

  @override
  int get freeItemsCount => 1;

  @override
  bool get canModifyQuantity => false;

  @override
  String getScanPrompt(int currentScanned) {
    return "Offerta 1+1 rilevata! Scansiona il 2° prodotto (quello in omaggio).";
  }
}

/// [DESIGN PATTERN: Concrete Strategy]
/// Implementazione specifica per la promozione "3x2".
class ThreeForTwoRule implements PromotionRule {
  @override
  String get type => AppStrings.promo3x2;

  @override
  int get requiredTotalItems => 3;

  @override
  int get freeItemsCount => 1;

  @override
  bool get canModifyQuantity => false;

  @override
  String getScanPrompt(int currentScanned) {
    return "Offerta 3x2 rilevata! Scansiona il ${currentScanned + 1}° prodotto.";
  }
}

/// [DESIGN PATTERN: Factory / Registry]
/// PromotionEngine funge da registro centrale per le regole promozionali.
/// In futuro, nuove regole possono essere registrate qui.
class PromotionEngine {
  static final List<PromotionRule> _rules = [
    OnePlusOneRule(),
    ThreeForTwoRule(),
  ];

  /// Restituisce la regola corrispondente al tipo di promo indicato, se supportata.
  static PromotionRule? getRule(String? promoType) {
    if (promoType == null) return null;
    
    // Cerchiamo una regola che gestisca questo tipo di promo
    // Nota: usiamo firstWhereOrNull se disponibile o una ricerca manuale
    for (var rule in _rules) {
      if (rule.type == promoType) {
        return rule;
      }
    }
    return null;
  }
  
  /// Metodo helper per verificare se un tipo di promo è gestito dal motore.
  static bool isSupported(String? promoType) {
    return getRule(promoType) != null;
  }
}
