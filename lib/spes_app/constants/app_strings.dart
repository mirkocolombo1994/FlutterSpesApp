class AppStrings {
  // SpesAppScreen
  static const String appTitle = 'SpesApp';
  static const String currentShopping = 'Spesa in Corso';
  static const String shoppingLists = 'Liste Spesa';
  static const String drawerMenuTitle = 'SpesApp Menu';
  static const String navCassa = 'Cassa';
  static const String navListe = 'Liste';
  static const String navHomePrincipale = 'Home Principale';
  static const String navImpostazioni = 'Impostazioni';
  static const String settingsTitle = 'Impostazioni';
  static const String appVersionPrefix = 'Versione App:';
  static const String themeModeLabel = 'Tema Scuro';
  static const String aboutAppLabel = 'Informazioni App';
  static const String aboutAppDescription = 'SpesApp - Gestione intelligente della spesa.\nSviluppato con Flutter.';
  static const String navProdotti = 'Prodotti';
  static const String navPuntiVendita = 'Punti Vendita';
  static const String navStorico = 'Storico Prezzi';
  static const String navCategorie = 'Categorie';
  static const String navPromozioni = 'Promozioni';

  // PromotionsScreen
  static const String titlePromotions = 'Promozioni';
  static const String subtitlePromotions = 'Gestisci le promo in corso per punto vendita';
  static const String addPromotionTitle = 'Nuova Promozione';
  static const String editPromotionTitle = 'Modifica Promozione';
  static const String noPromotionsText = 'Nessuna promozione registrata.';
  static const String validationNameRequired = 'Inserire il nome della promozione';
  static const String validationStoreRequired = 'Selezionare un punto vendita';
  static const String validationDateRequired = 'Inserire le date validità';
  static const String discountLabel = 'Sconto (%)';
  static const String validFromLabel = 'Valida dal:';
  static const String validUntilLabel = 'Giorno di fine:';

  // ProductDetailScreen
  static const String editProduct = 'Modifica Prodotto';
  static const String saveSuccess = 'Prodotto aggiornato con successo';
  static const String technicalDetails = 'Dettagli Tecnici';
  static const String latestPrices = 'Ultimi Prezzi Rilevati';
  static const String noPricesAvailable = 'Nessuna rilevazione prezzo disponibile.';
  static const String supermarket = 'Supermercato';
  static const String price = 'Prezzo';
  static const String date = 'Data';
  static const String descriptionLabel = 'Descrizione';
  static const String nameLabel = 'Nome Prodotto';
  static const String brandLabel = 'Marca';
  static const String categoryLabel = 'Categoria';
  static const String barcodeLabel = 'Barcode';
  static const String weightLabel = 'Formato';
  static const String selectCategoryHint = 'Seleziona categoria';

  // CategoriesScreen
  static const String manageCategories = 'Gestione Categorie';
  static const String newCategory = 'Nuova Categoria';
  static const String categoryNameHint = 'Nome categoria';
  static const String cancel = 'Annulla';
  static const String add = 'Aggiungi';
  static const String noCategoriesDefined = 'Nessuna categoria definita.';
  static const String addCategoryTooltip = 'Aggiungi Categoria';

  // AddProductScreen
  static const String newProduct = 'Nuovo Prodotto';
  static const String barcodeOptional = 'Codice a Barre (Opzionale)';
  static const String barcodeManualHelper = 'Lascia vuoto per inserimento manuale';
  static const String scanBarcodeTooltip = 'Scansiona codice';
  static const String productNameRequired = 'Nome *';
  static const String productNameValidator = 'Inserisci nome';
  static const String weightQuantity = 'Peso / Quantità';
  static const String pricePerKgAuto = 'Prezzo al Kg/L (€) (Auto)';
  static const String storeSelectionPrompt = 'In quale punto vendita ti trovi?';
  static const String addStoreTooltip = 'Aggiungi nuovo punto vendita';
  static const String recordedPriceRequired = 'Prezzo rilevato (€) *';
  static const String priceRequiredValidator = 'Inserisci prezzo';
  static const String priceInvalidValidator = 'Prezzo non valido';
  static const String promotionLabel = 'Promozione';
  static const String discountPercentLabel = 'Percentuale Sconto (%)';
  static const String noExpirySelected = 'Nessuna Scadenza Selezionata';
  static const String expiryDatePrefix = 'Fino al:';
  static const String freshProductDetected = '🏷️ Fresco riconosciuto: ';
  static const String productInArchive = '📦 Prodotto in archivio: ';
  static const String autoSetStore = '. Supermercato auto-impostato!';
  static const String newFreshProductAlert = '🏷️ Nuovo prodotto fresco! Memorizzalo. Prezzo estratto!';
  static const String selectStoreAndPriceWarning = 'Seleziona il punto vendita in cui ti trovi e il prezzo!';
  static const String productDataSection = 'Dati Prodotto';
  static const String priceEntrySection = 'Rilevazione Prezzo (Opzionale)';

  // ProductsScreen
  static const String myProductsTitle = 'I Miei Prodotti';
  static const String noSearchResults = 'Nessun prodotto trovato per la ricerca';
  static const String noProductsRegistered = 'Nessun prodotto censito';
  static const String deleteProductTitle = 'Elimina Prodotto';
  static const String deleteProductConfirmPrefix = 'Sei sicuro di voler eliminare "';
  static const String deleteProductConfirmSuffix = '"?';
  static const String sortAlphabetical = 'Alfabeticamente';
  static const String sortCategory = 'Per Categoria';
  static const String unknownCategory = 'Senza Categoria';
  static const String searchProductsHint = 'Cerca prodotti...';
  static const String noProductsFound = 'Nessun prodotto trovato.';

  // StoresScreen
  static const String navSupermercati = 'Supermercati';
  static const String noStoresSaved = 'Nessun supermercato salvato. Aggiungine uno!';
  static const String newStoreIndicator = 'NUOVO!';
  static const String storeClosedDefinitively = 'CHIUSO DEFINITIVAMENTE';
  static const String storeChainPrefix = 'Catena:';
  static const String storePhonePrefix = 'Tel:';
  static const String locationSavedOnMap = 'Posizione salvata sulla mappa';

  // AddStoreScreen
  static const String editStore = 'Modifica Supermercato';
  static const String newStore = 'Nuovo Supermercato';
  static const String searchStorePlaceholder = 'Cerca supermercato...';
  static const String storeFoundIndicator = '📍 Supermercato trovato!';
  static const String deleteStoreTitle = 'Elimina Punto Vendita';
  static const String reopenStoreTitle = 'Riapri Punto Vendita';
  static const String closeStoreTitle = 'Chiudi Punto Vendita';
  static const String deleteStoreConfirm = 'Sei sicuro di voler eliminare DEFINITIVAMENTE questo punto vendita?';
  static const String reopenStoreConfirm = 'Vuoi riaprire questo punto vendita?';
  static const String closeStoreConfirm = 'Vuoi contrassegnare questo punto vendita come chiuso definitivamente?';
  static const String deleteRelatedData = 'Elimina anche i prezzi e i prodotti esclusivi di questo supermercato';
  static const String storeClosedWarning = 'Questo punto vendita è CHIUSO.';
  static const String storeNameRequired = 'Nome Supermercato *';
  static const String enterStoreName = 'Inserisci un nome';
  static const String storeChainLabel = 'Catena (es. Esselunga, Conad)';
  static const String phoneLabel = 'Telefono';
  static const String selectLocationOnMap = 'Seleziona Posizione sulla Mappa';
  static const String coordinatesPrefix = 'Coordinate:';
  static const String confirmAction = 'Conferma';
  static const String markAsClosed = 'Segna come Chiuso';
  static const String deleteDefinitively = 'Elimina Definitivamente';

  // PriceHistoryScreen
  static const String priceHistoryTitle = 'Storico Prezzi';
  static const String lastPrice = 'Ultimo prezzo:';
  static const String selectProduct = 'Seleziona Prodotto';
  static const String selectStore = 'Seleziona Supermercato';
  static const String priceHistoryNotFound = 'Nessuno storico prezzi trovato.';
  static const String tabByProduct = 'Per Prodotto';
  static const String tabByStore = 'Per Punto Vendita';
  static const String productLabel = 'Prodotto';
  static const String unknownEntity = 'Ignoto';

  // CurrentShoppingScreen (Cassa)
  static const String currentShoppingTitle = 'Spesa in Corso';
  static const String emptyCart = 'Il tuo carrello è vuoto.\nScannerizza i prodotti mentre li metti nel carrello fisico per calcolare il totale in tempo reale!';
  static const String totalLabel = 'Totale Cassa:';
  static const String checkout = 'Concludi Spesa';
  static const String clearCartTooltip = 'Svuota Carrello';
  static const String storeSelectorLabel = 'Punto Vendita:';
  static const String storeNotDetected = 'Supermercato non rilevato';
  static const String changeStore = 'Cambia';
  static const String newStoreAutoSaved = '📍 Nuovo supermercato salvato in automatico:';
  static const String priceMissingInStore = 'Prezzo mancante in questo negozio';
  static const String productNotIndexedInStore = 'Prodotto non censito in questo negozio';
  static const String addProductLabel = 'Aggiungi Prodotto';
  static const String addedSuccess = '✅ Aggiunto:';
  static const String unknownProduct = 'Prodotto sconosciuto';
  static const String pricePerUnit = '€ cad.';
  static const String freshIndicatorLabel = 'Fresco';

  // ShoppingListsScreen
  static const String shoppingListsTitle = 'Le mie Liste Spesa';
  static const String createList = 'Crea nuova lista';
  static const String noListsFound = 'Nessuna lista creata.';
  static const String newListLabel = 'Nuova Lista';
  static const String listNameLabel = 'Nome Lista';
  static const String listTypeLabel = 'Tipo Lista';
  static const String selectStoreForList = 'Scegli un supermercato per la lista classica';
  static const String create = 'Crea';
  static const String listTypePrefix = 'Tipo:';

  // Promo Types
  static const String promoNone = 'Nessuna';
  static const String promoDiscountPercent = 'Sconto %';
  static const String promoCutPrice = 'Prezzo Tagliato';
  static const String promo1plus1 = '1+1';
  static const String promo3x2 = '3x2';
  static const String promoOther = 'Altro';

  // Units
  static const String unitKg = 'kg';
  static const String unitG = 'g';
  static const String unitL = 'l';
  static const String unitMl = 'ml';
  static const String unitPz = 'pz';

  // Common
  static const String save = 'Salva';
  static const String unknown = 'Sconosciuto';
  static const String loading = 'Caricamento...';
  static const String confirm = 'Conferma';
}
