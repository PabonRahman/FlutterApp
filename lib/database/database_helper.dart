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
      version: 2, // Increment version for new tables
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // ---------- Create initial tables ----------
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL,
        quantity INTEGER,
        category_id INTEGER,
        FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE
      )
    ''');

    // New tables added in version 2
    await db.execute('''
      CREATE TABLE purchases (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        date TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        quantity INTEGER,
        date TEXT,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');
  }

  // ---------- Upgrade database ----------
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add purchases table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS purchases (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER,
          quantity INTEGER,
          date TEXT,
          FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');

      // Add sales table if it doesn't exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sales (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER,
          quantity INTEGER,
          date TEXT,
          FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');
    }
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
    return db.insert('categories', {'name': name});
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final db = await database;
    return db.query('categories', orderBy: 'name');
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PRODUCT ----------
  Future<int> addProduct(String name, double price, int qty, int categoryId) async {
    final db = await database;
    return db.insert('products', {
      'name': name,
      'price': price,
      'quantity': qty,
      'category_id': categoryId,
    });
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    final db = await database;
    return db.rawQuery('''
      SELECT products.*, categories.name AS category
      FROM products
      LEFT JOIN categories ON products.category_id = categories.id
    ''');
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- PURCHASE ----------
  Future<int> addPurchase(int productId, int quantity, String date) async {
    final db = await database;
    return db.insert('purchases', {
      'product_id': productId,
      'quantity': quantity,
      'date': date,
    });
  }

  Future<List<Map<String, dynamic>>> getPurchases() async {
    final db = await database;
    return db.rawQuery('''
      SELECT purchases.*, products.name AS product
      FROM purchases
      LEFT JOIN products ON purchases.product_id = products.id
      ORDER BY date DESC
    ''');
  }

  Future<int> deletePurchase(int id) async {
    final db = await database;
    return db.delete('purchases', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- SALE ----------
  Future<int> addSale(int productId, int quantity, String date) async {
    final db = await database;
    return db.insert('sales', {
      'product_id': productId,
      'quantity': quantity,
      'date': date,
    });
  }

  Future<List<Map<String, dynamic>>> getSales() async {
    final db = await database;
    return db.rawQuery('''
      SELECT sales.*, products.name AS product
      FROM sales
      LEFT JOIN products ON sales.product_id = products.id
      ORDER BY date DESC
    ''');
  }

  Future<int> deleteSale(int id) async {
    final db = await database;
    return db.delete('sales', where: 'id = ?', whereArgs: [id]);
  }
}
