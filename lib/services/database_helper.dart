// lib/services/database_helper.dart
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:math';
import 'image_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;
  static const int _databaseVersion = 2;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'library_app.db');
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE books (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        imageUrl TEXT DEFAULT ''
      )
    ''');
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        name TEXT DEFAULT 'Kullanıcı'
      )
    ''');
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId INTEGER NOT NULL,
        bookId INTEGER NOT NULL,
        orderDate TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
        FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
      )
    ''');
    await _insertDemoData(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE books ADD COLUMN imageUrl TEXT DEFAULT ""');
      await db.execute('ALTER TABLE users ADD COLUMN name TEXT DEFAULT "Kullanıcı"');
      await db.execute('ALTER TABLE orders RENAME TO orders_old');
      await db.execute('''
        CREATE TABLE orders (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId INTEGER NOT NULL,
          bookId INTEGER NOT NULL,
          orderDate TEXT NOT NULL,
          quantity INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE,
          FOREIGN KEY (bookId) REFERENCES books (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        INSERT INTO orders (id, userId, bookId, orderDate, quantity)
        SELECT id, user_id, book_id, order_date, quantity FROM orders_old
      ''');
      await db.execute('DROP TABLE orders_old');
    }
  }

  // ========== DEMO VERİLERİ (pubspec.yaml ile uyumlu kısa isimler) ==========
  Future<void> _insertDemoData(Database db) async {
    // Kullanıcılar
    await db.insert('users', {
      'email': 'admin@library.com',
      'password': 'admin123',
      'role': 'admin',
      'name': 'Admin User',
    });
    await db.insert('users', {
      'email': 'user@library.com',
      'password': 'user123',
      'role': 'user',
      'name': 'Regular User',
    });

    // Kitaplar - asset isimleri pubspec.yaml ile aynı
    final List<Map<String, dynamic>> booksWithAssets = [
      {'title': 'Suç ve Ceza', 'author': 'Fyodor Dostoyevski', 'price': 42.5, 'stock': 7, 'imageAsset': 'assets/images/suc.png'},
      {'title': 'Sefiller', 'author': 'Victor Hugo', 'price': 38.0, 'stock': 5, 'imageAsset': 'assets/images/sefiller.png'},
      {'title': '1984', 'author': 'George Orwell', 'price': 35.0, 'stock': 10, 'imageAsset': 'assets/images/1984.png'},
      {'title': 'Kürk Mantolu Madonna', 'author': 'Sabahattin Ali', 'price': 28.5, 'stock': 8, 'imageAsset': 'assets/images/madonna.png'},
      {'title': 'Şeker Portakalı', 'author': 'José Mauro de Vasconcelos', 'price': 25.0, 'stock': 6, 'imageAsset': 'assets/images/portakal.png'},
      {'title': 'Benim Adım Kırmızı', 'author': 'Orhan Pamuk', 'price': 48.0, 'stock': 4, 'imageAsset': 'assets/images/kirmizi.png'},
    ];

    List<int> bookIds = [];
    for (var bookData in booksWithAssets) {
      String? localImagePath;
      try {
        String fileName = bookData['imageAsset'].split('/').last;
        localImagePath = await ImageService.copyAssetToLocal(bookData['imageAsset'], fileName);
      } catch (e) {
        print('Resim kopyalanamadı: ${bookData['title']} - $e');
        localImagePath = '';
      }

      int id = await db.insert('books', {
        'title': bookData['title'],
        'author': bookData['author'],
        'price': bookData['price'],
        'stock': bookData['stock'],
        'imageUrl': localImagePath ?? '',
      });
      bookIds.add(id);
    }

    // Rastgele siparişler (son 3 ay)
    Random rng = Random();
    DateTime now = DateTime.now();
    List<int> userIds = [1, 2];
    List<DateTime> months = [
      DateTime(now.year, now.month - 2, 1),
      DateTime(now.year, now.month - 1, 1),
      DateTime(now.year, now.month, 1),
    ];
    for (DateTime monthStart in months) {
      int daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
      int orderCount = 3 + rng.nextInt(5);
      for (int i = 0; i < orderCount; i++) {
        int day = 1 + rng.nextInt(daysInMonth);
        DateTime orderDate = DateTime(monthStart.year, monthStart.month, day);
        String isoDate = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
        int userId = userIds[rng.nextInt(userIds.length)];
        int bookId = bookIds[rng.nextInt(bookIds.length)];
        await db.insert('orders', {
          'userId': userId,
          'bookId': bookId,
          'orderDate': isoDate,
          'quantity': 1 + rng.nextInt(3),
        });
      }
    }
  }

  // ========== RESET BOOKS ONLY (aynı uyumlu assetler) ==========
  Future<void> resetBooksOnly() async {
    Database db = await database;

    // Eski kitapların resim dosyalarını sil
    final oldBooks = await getAllBooks();
    for (var book in oldBooks) {
      final imagePath = book['imageUrl'];
      if (imagePath != null && imagePath.isNotEmpty) {
        final file = File(imagePath);
        if (await file.exists()) await file.delete();
      }
    }

    await db.delete('books');

    // Aynı demo kitapları yeniden ekle (kısa isimler)
    final List<Map<String, dynamic>> booksWithAssets = [
      {'title': 'Suç ve Ceza', 'author': 'Fyodor Dostoyevski', 'price': 42.5, 'stock': 7, 'imageAsset': 'assets/images/suc.png'},
      {'title': 'Sefiller', 'author': 'Victor Hugo', 'price': 38.0, 'stock': 5, 'imageAsset': 'assets/images/sefiller.png'},
      {'title': '1984', 'author': 'George Orwell', 'price': 35.0, 'stock': 10, 'imageAsset': 'assets/images/1984.png'},
      {'title': 'Kürk Mantolu Madonna', 'author': 'Sabahattin Ali', 'price': 28.5, 'stock': 8, 'imageAsset': 'assets/images/madonna.png'},
      {'title': 'Şeker Portakalı', 'author': 'José Mauro de Vasconcelos', 'price': 25.0, 'stock': 6, 'imageAsset': 'assets/images/portakal.png'},
      {'title': 'Benim Adım Kırmızı', 'author': 'Orhan Pamuk', 'price': 48.0, 'stock': 4, 'imageAsset': 'assets/images/kirmizi.png'},
    ];

    for (var bookData in booksWithAssets) {
      String? localImagePath;
      try {
        String fileName = bookData['imageAsset'].split('/').last;
        localImagePath = await ImageService.copyAssetToLocal(bookData['imageAsset'], fileName);
      } catch (e) {
        print('Resim kopyalanamadı: ${bookData['title']} - $e');
        localImagePath = '';
      }

      await db.insert('books', {
        'title': bookData['title'],
        'author': bookData['author'],
        'price': bookData['price'],
        'stock': bookData['stock'],
        'imageUrl': localImagePath ?? '',
      });
    }
  }

  // ========== DİĞER METODLAR (CRUD vb.) ==========
  Future<int> insertBook(Map<String, dynamic> book) async {
    Database db = await database;
    return await db.insert('books', book);
  }

  Future<int> updateBook(Map<String, dynamic> book) async {
    Database db = await database;
    return await db.update('books', book, where: 'id = ?', whereArgs: [book['id']]);
  }

  Future<int> deleteBook(int id) async {
    Database db = await database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getAllBooks() async {
    Database db = await database;
    return await db.query('books');
  }

  // USER CRUD
  Future<int> insertUser(Map<String, dynamic> user) async {
    Database db = await database;
    return await db.insert('users', user);
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (result.isNotEmpty) return result.first;
    return null;
  }

  // ORDER CRUD
  Future<int> insertOrder(Map<String, dynamic> order) async {
    Database db = await database;
    return await db.insert('orders', order);
  }

  Future<List<Map<String, dynamic>>> getOrdersByUser(int userId) async {
    Database db = await database;
    String query = '''
      SELECT orders.id, orders.orderDate, orders.quantity,
             books.title as bookTitle, books.price as bookPrice
      FROM orders
      INNER JOIN books ON orders.bookId = books.id
      WHERE orders.userId = ?
      ORDER BY orders.orderDate DESC
    ''';
    return await db.rawQuery(query, [userId]);
  }

  // MONTHLY SALES
  Future<List<Map<String, dynamic>>> getMonthlySales() async {
    Database db = await database;
    String query = '''
      SELECT strftime('%Y-%m', orderDate) as month,
             SUM(quantity) as totalQuantity,
             SUM(quantity * books.price) as totalAmount
      FROM orders
      INNER JOIN books ON orders.bookId = books.id
      WHERE orderDate >= date('now', 'start of month', '-11 months')
      GROUP BY month
      ORDER BY month
    ''';
    return await db.rawQuery(query);
  }

  // STOK AZALT
  Future<bool> decreaseBookStock(int bookId, int quantity) async {
    Database db = await database;
    final result = await db.rawUpdate(
      'UPDATE books SET stock = stock - ? WHERE id = ? AND stock >= ?',
      [quantity, bookId, quantity],
    );
    return result > 0;
  }

  // FULL RESET
  Future<void> resetDatabase() async {
    Database db = await database;
    await db.delete('orders');
    await db.delete('books');
    await db.delete('users');
    await _insertDemoData(db);
  }

  // TAMAMEN YENİDEN OLUŞTUR
  Future<void> resetAndRecreate() async {
    Database db = await database;
    await db.execute('DROP TABLE IF EXISTS orders');
    await db.execute('DROP TABLE IF EXISTS books');
    await db.execute('DROP TABLE IF EXISTS users');
    await _onCreate(db, _databaseVersion);
  }
}