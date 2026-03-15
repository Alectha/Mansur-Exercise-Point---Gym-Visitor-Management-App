import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/member.dart';
import '../models/transaction.dart' as model;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('mansur_gym.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Members table
    await db.execute('''
      CREATE TABLE members (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        join_date TEXT NOT NULL,
        expire_date TEXT NOT NULL,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        transaction_type TEXT NOT NULL,
        price INTEGER NOT NULL,
        check_in_time TEXT NOT NULL,
        member_id INTEGER,
        created_at TEXT NOT NULL,
        FOREIGN KEY (member_id) REFERENCES members (id)
      )
    ''');

    // Settings table
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Insert default settings
    await db.insert('settings', {'key': 'wifi_password', 'value': 'MansurGym2026'});
    await db.insert('settings', {'key': 'daily_price', 'value': '15000'});
    await db.insert('settings', {'key': 'monthly_price', 'value': '300000'});
    await db.insert('settings', {'key': 'receipt_header', 'value': 'MANSUR EXERCISE POINT'});
    await db.insert('settings', {'key': 'receipt_footer', 'value': 'Terima Kasih & Selamat Berolahraga!'});
  }

  // Members CRUD
  Future<int> createMember(Member member) async {
    final db = await database;
    return await db.insert('members', member.toMap());
  }

  Future<List<Member>> getAllMembers() async {
    final db = await database;
    final result = await db.query('members', orderBy: 'created_at DESC');
    return result.map((json) => Member.fromMap(json)).toList();
  }

  Future<List<Member>> searchMembers(String name) async {
    final db = await database;
    final result = await db.query(
      'members',
      where: 'name LIKE ? AND status = ?',
      whereArgs: ['%$name%', 'active'],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => Member.fromMap(json)).toList();
  }

  Future<Member?> getMember(int id) async {
    final db = await database;
    final result = await db.query(
      'members',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return Member.fromMap(result.first);
    }
    return null;
  }

  // Transactions CRUD
  Future<int> createTransaction(model.Transaction transaction) async {
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<List<model.Transaction>> getTransactions({String? period, DateTime? date}) async {
    final db = await database;
    
    if (period == null || date == null) {
      final result = await db.query('transactions', orderBy: 'check_in_time DESC');
      return result.map((json) => model.Transaction.fromMap(json)).toList();
    }

    String whereClause;
    final dateStr = date.toIso8601String().split('T')[0];

    if (period == 'daily') {
      whereClause = 'DATE(check_in_time) = ?';
    } else if (period == 'weekly') {
      whereClause = "strftime('%Y-%W', check_in_time) = strftime('%Y-%W', ?)";
    } else {
      whereClause = "strftime('%Y-%m', check_in_time) = strftime('%Y-%m', ?)";
    }

    final result = await db.query(
      'transactions',
      where: whereClause,
      whereArgs: [dateStr],
      orderBy: 'check_in_time DESC',
    );

    return result.map((json) => model.Transaction.fromMap(json)).toList();
  }

  Future<model.Transaction?> getTransaction(int id) async {
    final db = await database;
    final result = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (result.isNotEmpty) {
      return model.Transaction.fromMap(result.first);
    }
    return null;
  }

  // Settings CRUD
  Future<String?> getSetting(String key) async {
    final db = await database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  Future<Map<String, String>> getAllSettings() async {
    final db = await database;
    final result = await db.query('settings');
    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['key'] as String,
        row['value'] as String,
      )),
    );
  }

  Future<void> updateSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
