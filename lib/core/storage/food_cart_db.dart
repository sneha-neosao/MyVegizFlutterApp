import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../../core/utils/logger.dart';

class FoodCartDb {
  static final FoodCartDb instance = FoodCartDb._init();
  static Database? _database;

  FoodCartDb._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('food_cart.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    logger.i('📂 FoodCartDb: Initializing SQLite database at $path');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logger.i('📂 FoodCartDb: Upgrading database from $oldVersion to $newVersion');
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE food_cart ADD COLUMN addon_ids TEXT');
      await db.execute('ALTER TABLE food_cart ADD COLUMN addon_data TEXT');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    logger.i('📂 FoodCartDb: Creating food_cart table');
    await db.execute('''
      CREATE TABLE food_cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_item_id INTEGER NOT NULL,
        vendor_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        image TEXT,
        description TEXT,
        cuisine_type TEXT,
        addon_ids TEXT,
        addon_data TEXT
      )
    ''');
  }

  Future<List<Map<String, dynamic>>> getCartItems() async {
    final db = await instance.database;
    final result = await db.query('food_cart');
    logger.d(
      '📂 FoodCartDb: Fetched ${result.length} item(s) from local database',
    );
    return result;
  }

  Future<int> getVendorId() async {
    final db = await instance.database;
    final result = await db.query(
      'food_cart',
      columns: ['vendor_id'],
      limit: 1,
    );
    if (result.isNotEmpty) {
      return result.first['vendor_id'] as int;
    }
    return 0;
  }

  Future<void> insertOrUpdateItem({
    required int vendorId,
    required int vendorItemId,
    required int quantity,
    required String name,
    required double price,
    String? image,
    String? description,
    String? cuisineType,
    String? addonIds, // JSON string
    String? addonData, // JSON string
  }) async {
    final db = await instance.database;

    // We check for exact match including addons to decide whether to increment quantity or insert new
    final maps = await db.query(
      'food_cart',
      where: 'vendor_item_id = ? AND (addon_ids = ? OR (addon_ids IS NULL AND ? IS NULL))',
      whereArgs: [vendorItemId, addonIds, addonIds],
    );

    if (maps.isNotEmpty) {
      final existingQty = maps.first['quantity'] as int;
      final newQty = existingQty + quantity;
      if (newQty <= 0) {
        await db.delete(
          'food_cart',
          where: 'id = ?',
          whereArgs: [maps.first['id']],
        );
      } else {
        logger.i(
          '📂 FoodCartDb: Updating quantity of item $vendorItemId (with addons) from $existingQty to $newQty',
        );
        await db.update(
          'food_cart',
          {'quantity': newQty},
          where: 'id = ?',
          whereArgs: [maps.first['id']],
        );
      }
    } else {
      if (quantity > 0) {
        logger.i(
          '📂 FoodCartDb: Inserting new food item $vendorItemId (vendorId: $vendorId) with addons',
        );
        await db.insert('food_cart', {
          'vendor_item_id': vendorItemId,
          'vendor_id': vendorId,
          'quantity': quantity,
          'name': name,
          'price': price,
          'image': image,
          'description': description,
          'cuisine_type': cuisineType,
          'addon_ids': addonIds,
          'addon_data': addonData,
        });
      }
    }
  }

  Future<void> updateItemQuantity(int id, int quantity) async {
    final db = await instance.database;
    if (quantity <= 0) {
      await removeItem(id);
    } else {
      logger.i(
        '📂 FoodCartDb: Updating item ID $id quantity to $quantity',
      );
      await db.update(
        'food_cart',
        {'quantity': quantity},
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }

  Future<void> removeItem(int id) async {
    final db = await instance.database;
    logger.i('📂 FoodCartDb: Removing item ID $id');
    await db.delete(
      'food_cart',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearCart() async {
    final db = await instance.database;
    logger.i('📂 FoodCartDb: Clearing all items from cart');
    await db.delete('food_cart');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
