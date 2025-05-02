import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';

class LocalDatabase {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'products.db');
    return await openDatabase(
      path,
      version: 2, // Versão do banco foi alterada
      onCreate: (db, version) {
        return db.execute(
          '''CREATE TABLE products (
              id TEXT PRIMARY KEY,
              nome TEXT,
              estoque INTEGER,
              disponivel INTEGER,
              preco1 TEXT,
              preco2 TEXT,
              loja TEXT
            )''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Adiciona a coluna 'loja' caso seja necessário
          await db.execute("ALTER TABLE products ADD COLUMN loja TEXT");
        }
      },
    );
  }

  static Future<void> insertProducts(List<Product> products, String store) async {
    final db = await database;
    // Deleta os produtos antigos antes de inserir novos
    await db.delete('products', where: 'loja = ?', whereArgs: [store]); 
    for (var p in products) {
      await db.insert('products', {...p.toMap(), 'loja': store});
    }
  }

  static Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products');
    return maps.map((e) => Product.fromMap(e)).toList();
  }
  static Future<List<Product>> getProductsByStore(String loja) async {
    final db = await database;
    final maps = await db.query('products', where: 'loja = ?', whereArgs: [loja]);
    return maps.map((e) => Product.fromMap(e)).toList();
  }
}
