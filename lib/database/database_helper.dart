import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // ---------- Database getter ----------
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
      version: 6, // Increment to 6 for fresh start
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        // For simplicity, drop all tables and recreate
        if (oldVersion < 6) {
          await db.execute('DROP TABLE IF EXISTS purchases');
          await db.execute('DROP TABLE IF EXISTS sales');
          await db.execute('DROP TABLE IF EXISTS products');
          await db.execute('DROP TABLE IF EXISTS categories');
          await db.execute('DROP TABLE IF EXISTS users');
          await _createDB(db, newVersion);
        }
      },
    );
  }

  // ---------- Create initial tables ----------
  Future _createDB(Database db, int version) async {
    print('Creating database tables version $version');
    
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL CHECK(price >= 0),
        quantity INTEGER NOT NULL CHECK(quantity >= 0) DEFAULT 0,
        category_id INTEGER NOT NULL,
        created_at TEXT,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE RESTRICT
      )
    ''');

    // CORRECTED: Using unit_price (with underscore)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        unit_price REAL NOT NULL CHECK(unit_price >= 0),
        total_price REAL NOT NULL CHECK(total_price >= 0),
        date TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');

    // CORRECTED: Using unit_price (with underscore)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL CHECK(quantity > 0),
        unit_price REAL NOT NULL CHECK(unit_price >= 0),
        total_price REAL NOT NULL CHECK(total_price >= 0),
        date TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE RESTRICT
      )
    ''');
    
    print('Database tables created successfully');
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
    return db.insert('categories', {
      'name': name,
      'created_at': now,
    });
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
    // Check if category has products
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

  // ---------- PRODUCT ----------
  Future<int> addProduct(String name, double price, int qty, int categoryId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    return db.insert('products', {
      'name': name,
      'price': price,
      'quantity': qty,
      'category_id': categoryId,
      'created_at': now,
      'updated_at': now,
    });
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    try {
      return await db.rawQuery('''
        SELECT 
          products.*, 
          categories.name AS category_name
        FROM products
        LEFT JOIN categories ON products.category_id = categories.id
        ORDER BY products.name
      ''');
    } catch (e) {
      print('Error getting products: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getProduct(int id) async {
    final db = await database;
    try {
      final res = await db.query(
        'products',
        where: 'id = ?',
        whereArgs: [id],
      );
      return res.isNotEmpty ? res.first : null;
    } catch (e) {
      print('Error getting product $id: $e');
      return null;
    }
  }

  Future<int> updateProduct(int id, String name, double price, int quantity, int categoryId) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'name': name,
        'price': price,
        'quantity': quantity,
        'category_id': categoryId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateProductQuantity(int id, int newQuantity) async {
    final db = await database;
    return await db.update(
      'products',
      {
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PURCHASE ----------
  Future<int> addPurchase(int productId, int quantity, double unitPrice) async {
    final db = await database;
    
    print('Adding purchase: productId=$productId, quantity=$quantity, unitPrice=$unitPrice');
    
    // Start transaction
    await db.execute('BEGIN TRANSACTION');
    
    try {
      // Get current product
      final product = await getProduct(productId);
      if (product == null) {
        throw Exception('Product not found');
      }
      
      // Calculate total price
      final totalPrice = quantity * unitPrice;
      final now = DateTime.now().toIso8601String();
      
      print('Inserting into purchases table with unit_price: $unitPrice');
      
      // Insert purchase record
      final purchaseId = await db.insert('purchases', {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'date': now,
      });
      
      // Update product quantity
      final newQuantity = (product['quantity'] as int) + quantity;
      await updateProductQuantity(productId, newQuantity);
      
      // Commit transaction
      await db.execute('COMMIT');
      print('Purchase added successfully with ID: $purchaseId');
      return purchaseId;
    } catch (e) {
      // Rollback on error
      await db.execute('ROLLBACK');
      print('Error adding purchase: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final db = await database;
    try {
      return await db.rawQuery('''
        SELECT 
          purchases.*,
          products.name AS product_name,
          categories.name AS category_name
        FROM purchases
        JOIN products ON purchases.product_id = products.id
        JOIN categories ON products.category_id = categories.id
        ORDER BY purchases.date DESC
      ''');
    } catch (e) {
      print('Error getting purchases: $e');
      return [];
    }
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    
    // Start transaction
    await db.execute('BEGIN TRANSACTION');
    
    try {
      // Get purchase details
      final purchase = await db.query(
        'purchases',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (purchase.isEmpty) {
        throw Exception('Purchase not found');
      }
      
      final productId = purchase.first['product_id'] as int;
      final quantity = purchase.first['quantity'] as int;
      
      // Get current product quantity
      final product = await getProduct(productId);
      if (product == null) {
        throw Exception('Product not found');
      }
      
      // Check if we have enough stock to deduct
      final currentQty = product['quantity'] as int;
      if (currentQty < quantity) {
        throw Exception('Insufficient stock to reverse this purchase');
      }
      
      // Update product quantity (subtract)
      final newQuantity = currentQty - quantity;
      await updateProductQuantity(productId, newQuantity);
      
      // Delete purchase record
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

  // ---------- SALE ----------
  Future<int> addSale(int productId, int quantity) async {
    final db = await database;
    
    // Start transaction
    await db.execute('BEGIN TRANSACTION');
    
    try {
      // Get product with current price
      final product = await getProduct(productId);
      if (product == null) {
        throw Exception('Product not found');
      }
      
      final currentQty = product['quantity'] as int;
      final unitPrice = product['price'] as double;
      
      // Check stock availability
      if (currentQty < quantity) {
        throw Exception('Insufficient stock. Available: $currentQty');
      }
      
      // Calculate total price
      final totalPrice = quantity * unitPrice;
      final now = DateTime.now().toIso8601String();
      
      // Insert sale record
      final saleId = await db.insert('sales', {
        'product_id': productId,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'date': now,
      });
      
      // Update product quantity
      final newQuantity = currentQty - quantity;
      await updateProductQuantity(productId, newQuantity);
      
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
        SELECT 
          sales.*,
          products.name AS product_name,
          categories.name AS category_name
        FROM sales
        JOIN products ON sales.product_id = products.id
        JOIN categories ON products.category_id = categories.id
        ORDER BY sales.date DESC
      ''');
    } catch (e) {
      print('Error getting sales: $e');
      return [];
    }
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    
    await db.execute('BEGIN TRANSACTION');
    
    try {
      // Get sale details
      final sale = await db.query(
        'sales',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (sale.isEmpty) {
        throw Exception('Sale not found');
      }
      
      final productId = sale.first['product_id'] as int;
      final quantity = sale.first['quantity'] as int;
      
      // Get current product
      final product = await getProduct(productId);
      if (product == null) {
        throw Exception('Product not found');
      }
      
      // Update product quantity (add back)
      final currentQty = product['quantity'] as int;
      final newQuantity = currentQty + quantity;
      await updateProductQuantity(productId, newQuantity);
      
      // Delete sale record
      final result = await db.delete(
        'sales',
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

  // ---------- DASHBOARD STATS ----------
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final products = await getProducts();
      final categories = await getCategories();
      final purchases = await getPurchases();
      final sales = await getSales();
      
      int totalQuantity = products.fold(0, (sum, p) => sum + (p['quantity'] as int? ?? 0));
      
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
        'totalQuantity': totalQuantity,
        'totalPurchaseValue': totalPurchaseValue,
        'totalSaleValue': totalSaleValue,
        'profit': totalSaleValue - totalPurchaseValue,
      };
    } catch (e) {
      print('Error getting dashboard stats: $e');
      return {
        'totalProducts': 0,
        'totalCategories': 0,
        'totalQuantity': 0,
        'totalPurchaseValue': 0.0,
        'totalSaleValue': 0.0,
        'profit': 0.0,
      };
    }
  }
}