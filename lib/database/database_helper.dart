import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('inventory.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at TEXT
      )
    ''');

    // Warehouses table
    await db.execute('''
      CREATE TABLE warehouses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        capacity INTEGER DEFAULT 0,
        manager TEXT,
        phone TEXT,
        email TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        category_id INTEGER NOT NULL,
        warehouse_id INTEGER,
        image_path TEXT,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id),
        FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)
      )
    ''');

    // Purchases table
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        date TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    // Sales table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        total_price REAL NOT NULL,
        date TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT;');
    }
  }

  // ---------- UTILITY ----------
  Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'inventory.db');

    try {
      await deleteDatabase(path);
    } catch (e) {
      // Ignore delete errors
    }

    await database;
  }

  // ---------- AUTH ----------
  Future<int> registerUser(String name, String email, String password) async {
    final db = await database;
    return db.insert('users', {
      'name': name,
      'email': email,
      'password': password,
    });
  }

  Future<bool> loginUser(String email, String password) async {
    final db = await database;
    final res = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    return res.isNotEmpty;
  }

  // ---------- CATEGORY ----------
  Future<int> addCategory(String name) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert('categories', {'name': name, 'created_at': now});
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('categories', orderBy: 'name');
  }

  Future<int> updateCategory(int id, String name) async {
    final db = await database;
    return await db.update(
      'categories',
      {'name': name},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    final products = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [id],
    );

    if (products.isNotEmpty) {
      throw Exception('Cannot delete category with existing products');
    }

    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- WAREHOUSE ----------
  Future<int> addWarehouse(Map<String, dynamic> warehouse) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert('warehouses', {
      'name': warehouse['name'],
      'location': warehouse['location'],
      'capacity': warehouse['capacity'],
      'manager': warehouse['manager'],
      'phone': warehouse['phone'],
      'email': warehouse['email'],
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getWarehouses() async {
    final db = await database;
    return db.query('warehouses', orderBy: 'name');
  }

  Future<Map<String, dynamic>?> getWarehouse(int id) async {
    final db = await database;
    final res = await db.query('warehouses', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateWarehouse(int id, Map<String, dynamic> warehouse) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.update(
      'warehouses',
      {
        'name': warehouse['name'],
        'location': warehouse['location'],
        'capacity': warehouse['capacity'],
        'manager': warehouse['manager'],
        'phone': warehouse['phone'],
        'email': warehouse['email'],
        'updated_at': now,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteWarehouse(int id) async {
    final db = await database;
    final products = await db.query(
      'products',
      where: 'warehouse_id = ?',
      whereArgs: [id],
    );

    if (products.isNotEmpty) {
      throw Exception('Cannot delete warehouse with existing products');
    }

    return db.delete('warehouses', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PRODUCT ----------
  Future<int> addProduct(
    String name,
    int quantity,
    int categoryId,
    int? warehouseId,
    String? imagePath,
  ) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert('products', {
      'name': name,
      'quantity': quantity,
      'category_id': categoryId,
      'warehouse_id': warehouseId,
      'image_path': imagePath,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<int> updateProduct(
    int id,
    String name,
    int quantity,
    int categoryId,
    int? warehouseId,
    String? imagePath,
  ) async {
    final db = await database;
    return db.update(
      'products',
      {
        'name': name,
        'quantity': quantity,
        'category_id': categoryId,
        'warehouse_id': warehouseId,
        'image_path': imagePath,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    try {
      return await db.rawQuery('''
        SELECT 
          products.*, 
          categories.name AS category_name,
          warehouses.name AS warehouse_name,
          warehouses.location AS warehouse_location
        FROM products
        LEFT JOIN categories ON products.category_id = categories.id
        LEFT JOIN warehouses ON products.warehouse_id = warehouses.id
        ORDER BY products.name
      ''');
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getProductsByWarehouse(
    int warehouseId,
  ) async {
    final db = await database;
    try {
      return await db.rawQuery(
        '''
        SELECT 
          products.*, 
          categories.name AS category_name
        FROM products
        LEFT JOIN categories ON products.category_id = categories.id
        WHERE products.warehouse_id = ?
        ORDER BY products.name
      ''',
        [warehouseId],
      );
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProduct(int id) async {
    final db = await database;
    final res = await db.query('products', where: 'id = ?', whereArgs: [id]);
    return res.isNotEmpty ? res.first : null;
  }

  Future<int> updateProductQuantity(int id, int newQuantity) async {
    final db = await database;
    return await db.update(
      'products',
      {'quantity': newQuantity, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PURCHASE ----------
  Future<int> addPurchase(int productId, int quantity, double unitPrice) async {
    final db = await database;
    await db.execute('BEGIN TRANSACTION');
    try {
      final product = await getProduct(productId);
      if (product == null) throw Exception('Product not found');
      final totalPrice = quantity * unitPrice;
      final now = DateTime.now().toIso8601String();
      final purchaseId = await db.insert('purchases', {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'date': now,
      });
      final newQuantity = (product['quantity'] as int) + quantity;
      await updateProductQuantity(productId, newQuantity);
      await db.execute('COMMIT');
      return purchaseId;
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final db = await database;
    try {
      return await db.rawQuery('''
        SELECT purchases.*, products.name AS product_name, categories.name AS category_name
        FROM purchases
        JOIN products ON purchases.product_id = products.id
        JOIN categories ON products.category_id = categories.id
        ORDER BY purchases.date DESC
      ''');
    } catch (e) {
      return [];
    }
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    await db.execute('BEGIN TRANSACTION');
    try {
      final purchase = await db.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (purchase.isEmpty) throw Exception('Purchase not found');
      final productId = purchase.first['product_id'] as int;
      final quantity = purchase.first['quantity'] as int;
      final product = await getProduct(productId);
      if (product == null) throw Exception('Product not found');
      final newQuantity = (product['quantity'] as int) - quantity;
      await updateProductQuantity(productId, newQuantity);
      final result = await db.delete(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
      );
      await db.execute('COMMIT');
      return result;
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> deleteAllPurchases() async {
    final db = await database;
    await db.delete('purchases');
  }

  // ---------- SALE ----------
  Future<int> addSale(int productId, int quantity, double unitPrice) async {
    final db = await database;
    await db.execute('BEGIN TRANSACTION');
    try {
      final product = await getProduct(productId);
      if (product == null) throw Exception('Product not found');
      final currentQty = product['quantity'] as int;
      if (currentQty < quantity) throw Exception('Insufficient stock');
      final totalPrice = quantity * unitPrice;
      final now = DateTime.now().toIso8601String();
      final saleId = await db.insert('sales', {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'date': now,
      });
      await updateProductQuantity(productId, currentQty - quantity);
      await db.execute('COMMIT');
      return saleId;
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    try {
      return await db.rawQuery('''
        SELECT sales.*, products.name AS product_name, categories.name AS category_name
        FROM sales
        JOIN products ON sales.product_id = products.id
        JOIN categories ON products.category_id = categories.id
        ORDER BY sales.date DESC
      ''');
    } catch (e) {
      return [];
    }
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    await db.execute('BEGIN TRANSACTION');
    try {
      final sale = await db.query('sales', where: 'id = ?', whereArgs: [id]);
      if (sale.isEmpty) throw Exception('Sale not found');
      final productId = sale.first['product_id'] as int;
      final quantity = sale.first['quantity'] as int;
      final product = await getProduct(productId);
      if (product == null) throw Exception('Product not found');
      await updateProductQuantity(
        productId,
        (product['quantity'] as int) + quantity,
      );
      final result = await db.delete('sales', where: 'id = ?', whereArgs: [id]);
      await db.execute('COMMIT');
      return result;
    } catch (e) {
      await db.execute('ROLLBACK');
      rethrow;
    }
  }

  Future<void> deleteAllSales() async {
    final db = await database;
    await db.delete('sales');
  }

  // ---------- DASHBOARD STATS ----------
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final products = await getProducts();
      final categories = await getCategories();
      final warehouses = await getWarehouses();
      final purchases = await getPurchases();
      final sales = await getSales();

      int totalQuantity = products.fold(
        0,
        (sum, p) => sum + (p['quantity'] as int? ?? 0),
      );

      double totalPurchaseValue = purchases.fold(0.0, (sum, p) {
        final price = p['total_price'];
        return sum + (price is num ? price.toDouble() : 0.0);
      });

      double totalSaleValue = sales.fold(0.0, (sum, s) {
        final price = s['total_price'];
        return sum + (price is num ? price.toDouble() : 0.0);
      });

      return {
        'totalProducts': products.length,
        'totalCategories': categories.length,
        'totalWarehouses': warehouses.length,
        'totalQuantity': totalQuantity,
        'totalPurchaseValue': totalPurchaseValue,
        'totalSaleValue': totalSaleValue,
        'profit': totalSaleValue - totalPurchaseValue,
      };
    } catch (e) {
      return {
        'totalProducts': 0,
        'totalCategories': 0,
        'totalWarehouses': 0,
        'totalQuantity': 0,
        'totalPurchaseValue': 0.0,
        'totalSaleValue': 0.0,
        'profit': 0.0,
      };
    }
  }

  // ---------- WAREHOUSE STATS ----------
  Future<Map<String, dynamic>> getWarehouseStats(int warehouseId) async {
    try {
      // Get products in this warehouse
      final products = await getProductsByWarehouse(warehouseId);

      // Get warehouse details
      final warehouse = await getWarehouse(warehouseId);

      // Calculate total quantity
      int totalQuantity = products.fold(
        0,
        (sum, p) => sum + (p['quantity'] as int? ?? 0),
      );

      // Get capacity
      int capacity = warehouse?['capacity'] as int? ?? 0;
      double occupancy = capacity > 0 ? (totalQuantity / capacity) * 100 : 0.0;

      return {
        'totalProducts': products.length,
        'totalQuantity': totalQuantity,
        'capacity': capacity,
        'occupancy': occupancy,
      };
    } catch (e) {
      return {
        'totalProducts': 0,
        'totalQuantity': 0,
        'capacity': 0,
        'occupancy': 0.0,
      };
    }
  }
}