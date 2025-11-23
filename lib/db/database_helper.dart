import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/contact.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contacts.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE contacts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      phone TEXT NOT NULL
    )
    ''');
  }

  Future<Contact> create(Contact contact) async {
    final db = await instance.database;
    final id = await db.insert('contacts', contact.toMap());
    contact.id = id;
    return contact;
  }

  Future<List<Contact>> readAllContacts() async {
    final db = await instance.database;
    final result = await db.query('contacts', orderBy: 'name ASC');
    return result.map((e) => Contact.fromMap(e)).toList();
  }

  Future<int> update(Contact contact) async {
    final db = await instance.database;
    return db.update('contacts', contact.toMap(), where: 'id = ?', whereArgs: [contact.id]);
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return db.delete('contacts', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
