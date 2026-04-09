import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/store.dart';
import '../models/product.dart';
import '../models/price_history.dart';
import '../models/category.dart';
import '../models/promotion.dart';
import '../models/shopping_list.dart';
import '../models/shopping_list_item.dart';

class SpesAppDatabaseHelper {
  static final SpesAppDatabaseHelper instance = SpesAppDatabaseHelper._init();
  static Database? _database;

  SpesAppDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('spes_app.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN price_per_kg REAL');
      } catch (_) {
        // Ignora in caso esista già durante lo sviluppo
      }
    }
    if (oldVersion < 3) {
      try {
        await db.execute('ALTER TABLE stores ADD COLUMN is_closed INTEGER DEFAULT 0');
      } catch (_) {}
    }
    if (oldVersion < 5) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN image_url TEXT');
        await db.execute('ALTER TABLE products ADD COLUMN category TEXT');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE categories (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      try {
        await db.execute('''
          CREATE TABLE promotions (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            discount_percentage REAL,
            store_id TEXT NOT NULL,
            valid_from INTEGER,
            valid_until INTEGER,
            FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 8) {
      try {
        await db.execute('ALTER TABLE products ADD COLUMN raw_off_data TEXT');
      } catch (_) {}
    }
    if (oldVersion < 9) {
      try {
        await db.execute('''
          CREATE TABLE promotion_products (
            promo_id TEXT,
            product_barcode TEXT,
            PRIMARY KEY (promo_id, product_barcode),
            FOREIGN KEY (promo_id) REFERENCES promotions (id) ON DELETE CASCADE,
            FOREIGN KEY (product_barcode) REFERENCES products (barcode) ON DELETE CASCADE
          )
        ''');
      } catch (_) {}
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE stores (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        chain TEXT,
        phone TEXT,
        latitude REAL,
        longitude REAL,
        is_closed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE promotions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        discount_percentage REAL,
        store_id TEXT NOT NULL,
        valid_from INTEGER,
        valid_until INTEGER,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE CASCADE
      )
    ''');
    
    await db.execute('''
      CREATE TABLE products (
        barcode TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        brand TEXT,
        weight REAL,
        weight_unit TEXT,
        price_per_kg REAL,
        image_url TEXT,
        category TEXT,
        raw_off_data TEXT
      )
    ''');
    
    await db.execute('''
      CREATE TABLE promotion_products (
        promo_id TEXT,
        product_barcode TEXT,
        PRIMARY KEY (promo_id, product_barcode),
        FOREIGN KEY (promo_id) REFERENCES promotions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_barcode) REFERENCES products (barcode) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE price_history (
        id TEXT PRIMARY KEY,
        product_barcode TEXT NOT NULL,
        store_id TEXT NOT NULL,
        price REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        promo_type TEXT,
        promo_valid_until INTEGER,
        FOREIGN KEY (product_barcode) REFERENCES products (barcode) ON DELETE CASCADE,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_lists (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        store_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_list_items (
        id TEXT PRIMARY KEY,
        list_id TEXT NOT NULL,
        product_barcode TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        is_checked INTEGER NOT NULL DEFAULT 0,
        store_id TEXT,
        FOREIGN KEY (list_id) REFERENCES shopping_lists (id) ON DELETE CASCADE,
        FOREIGN KEY (product_barcode) REFERENCES products (barcode) ON DELETE CASCADE,
        FOREIGN KEY (store_id) REFERENCES stores (id) ON DELETE SET NULL
      )
    ''');
  }

  // --- STORE METHODS ---
  Future<void> insertStore(Store store) async {
    final db = await instance.database;
    await db.insert('stores', store.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Store>> getStores() async {
    final db = await instance.database;
    final result = await db.query('stores');
    return result.map((json) => Store.fromMap(json)).toList();
  }

  Future<Store?> getStoreById(String id) async {
    final db = await instance.database;
    final result = await db.query('stores', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) return Store.fromMap(result.first);
    return null;
  }

  Future<void> updateStore(Store store) async {
    final db = await instance.database;
    await db.update('stores', store.toMap(), where: 'id = ?', whereArgs: [store.id]);
  }

  Future<void> deleteStore(String id) async {
    final db = await instance.database;
    await db.delete('stores', where: 'id = ?', whereArgs: [id]);
  }

  // --- CLEANUP ---
  Future<void> deleteProductsExclusiveToStore(String storeId) async {
    final db = await instance.database;
    final currentStoreHistories = await db.query('price_history', where: 'store_id = ?', whereArgs: [storeId]);
    final productBarcodes = currentStoreHistories.map((h) => h['product_barcode'] as String).toSet().toList();
    
    for (String barcode in productBarcodes) {
      final otherStoresCountResult = await db.rawQuery(
        'SELECT COUNT(DISTINCT store_id) as c FROM price_history WHERE product_barcode = ? AND store_id != ?',
        [barcode, storeId]
      );
      int count = otherStoresCountResult.first['c'] as int;
      if (count == 0) {
        await db.delete('products', where: 'barcode = ?', whereArgs: [barcode]);
      }
    }
  }

  Future<void> deletePriceHistoryForStore(String storeId) async {
    final db = await instance.database;
    await db.delete('price_history', where: 'store_id = ?', whereArgs: [storeId]);
  }

  // --- PRODUCT METHODS ---
  Future<void> insertProduct(Product product) async {
    final db = await instance.database;
    await db.insert('products', product.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Product>> getProducts() async {
    final db = await instance.database;
    final result = await db.query('products');
    return result.map((json) => Product.fromMap(json)).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final result = await db.query('products', where: 'barcode = ?', whereArgs: [barcode]);
    if (result.isNotEmpty) return Product.fromMap(result.first);
    return null;
  }

  Future<void> deleteProduct(String barcode) async {
    final db = await instance.database;
    await db.delete('products', where: 'barcode = ?', whereArgs: [barcode]);
  }

  // --- METODI PER LE CATEGORIE ---

  /// Aggiunge o aggiorna una categoria nel database
  Future<void> insertCategory(Category category) async {
    final db = await instance.database;
    await db.insert('categories', category.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Recupera tutte le categorie salvate, ordinate alfabeticamente
  Future<List<Category>> getCategories() async {
    final db = await instance.database;
    final result = await db.query('categories', orderBy: 'name ASC');
    return result.map((json) => Category.fromMap(json)).toList();
  }

  /// Elimina una categoria tramite il suo ID
  Future<void> deleteCategory(String id) async {
    final db = await instance.database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // --- PROMOTIONS METHODS ---
  Future<void> insertPromotion(Promotion promotion) async {
    final db = await instance.database;
    await db.insert('promotions', promotion.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Promotion>> getPromotions() async {
    final db = await instance.database;
    final result = await db.query('promotions');
    return result.map((json) => Promotion.fromMap(json)).toList();
  }

  Future<void> deletePromotion(String id) async {
    final db = await instance.database;
    
    // Recuperiamo i dettagli della promo prima di cancellarla per pulire lo storico
    final List<Map<String, dynamic>> promoMaps = await db.query(
      'promotions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (promoMaps.isNotEmpty) {
      final String promoName = promoMaps.first['name'];
      final String storeId = promoMaps.first['store_id'];

      // 1. Cancelliamo la promo (la tabella promotion_products si pulisce via CASCADE)
      await db.delete('promotions', where: 'id = ?', whereArgs: [id]);

      // 2. Puliamo lo storico prezzi: se un prezzo aveva questa promo, la rimuoviamo
      // così l'app non la "risuggerisce" più come attiva.
      await db.update(
        'price_history',
        {
          'promo_type': null,
          'promo_valid_until': null,
        },
        where: 'store_id = ? AND promo_type = ?',
        whereArgs: [storeId, promoName],
      );
    }
  }

  // --- PROMOTION PRODUCTS METHODS ---
  Future<void> linkProductToPromotion(String promoId, String productBarcode) async {
    final db = await instance.database;
    await db.insert('promotion_products', {
      'promo_id': promoId,
      'product_barcode': productBarcode,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> unlinkProductFromPromotion(String promoId, String productBarcode) async {
    final db = await instance.database;
    await db.delete('promotion_products', 
      where: 'promo_id = ? AND product_barcode = ?', 
      whereArgs: [promoId, productBarcode]);
  }

  Future<List<Product>> getProductsForPromotion(String promoId) async {
    final db = await instance.database;
    // Join promotion_products with products
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT p.* 
      FROM products p
      INNER JOIN promotion_products pp ON p.barcode = pp.product_barcode
      WHERE pp.promo_id = ?
    ''', [promoId]);
    return List.generate(maps.length, (i) => Product.fromMap(maps[i]));
  }

  // --- PRICE HISTORY METHODS ---
  Future<void> insertPriceHistory(PriceHistory ph) async {
    final db = await instance.database;
    await db.insert('price_history', ph.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<PriceHistory>> getPriceHistoryForProduct(String barcode) async {
    final db = await instance.database;
    final result = await db.query(
      'price_history', 
      where: 'product_barcode = ?', 
      whereArgs: [barcode],
      orderBy: 'timestamp DESC'
    );
    return result.map((json) => PriceHistory.fromMap(json)).toList();
  }

  Future<List<PriceHistory>> getPriceHistoryForStore(String storeId) async {
    final db = await instance.database;
    final result = await db.query(
      'price_history', 
      where: 'store_id = ?', 
      whereArgs: [storeId],
      orderBy: 'timestamp DESC'
    );
    return result.map((json) => PriceHistory.fromMap(json)).toList();
  }

  // --- SHOPPING LIST METHODS ---
  Future<void> insertShoppingList(ShoppingList list) async {
    final db = await instance.database;
    await db.insert('shopping_lists', list.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<ShoppingList>> getShoppingLists() async {
    final db = await instance.database;
    final result = await db.query('shopping_lists', orderBy: 'created_at DESC');
    return result.map((json) => ShoppingList.fromMap(json)).toList();
  }

  Future<void> updateShoppingList(ShoppingList list) async {
    final db = await instance.database;
    await db.update('shopping_lists', list.toMap(), where: 'id = ?', whereArgs: [list.id]);
  }

  Future<void> deleteShoppingList(String id) async {
    final db = await instance.database;
    await db.delete('shopping_lists', where: 'id = ?', whereArgs: [id]);
    // Note: Items are cascade deleted because of foreign key, but SQLite needs pragma foreign_keys = ON;
    // We should enable it in _initDB actually. We will do this later if needed.
  }

  // --- SHOPPING LIST ITEM METHODS ---
  Future<void> insertShoppingListItem(ShoppingListItem item) async {
    final db = await instance.database;
    await db.insert('shopping_list_items', item.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }
  
  Future<void> updateShoppingListItem(ShoppingListItem item) async {
    final db = await instance.database;
    await db.update('shopping_list_items', item.toMap(), where: 'id = ?', whereArgs: [item.id]);
  }

  Future<void> deleteShoppingListItem(String id) async {
    final db = await instance.database;
    await db.delete('shopping_list_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<ShoppingListItem>> getShoppingListItems(String listId) async {
    final db = await instance.database;
    final result = await db.query('shopping_list_items', where: 'list_id = ?', whereArgs: [listId]);
    return result.map((json) => ShoppingListItem.fromMap(json)).toList();
  }
}
